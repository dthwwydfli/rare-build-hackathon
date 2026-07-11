import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/urge_log.dart';

class UrgeLogScreen extends ConsumerWidget {
  const UrgeLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final urgesAsync = ref.watch(_urgesProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Urges')),
      body: urgesAsync.when(
        data: (urges) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_urgesProvider(user.id)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _QuickUrgeForm(userId: user.id),
              const SizedBox(height: 16),
              _ConfidenceCard(urges: urges),
              const SizedBox(height: 16),
              _RiskPromptCard(urges: urges),
              const SizedBox(height: 24),
              Text('Patterns', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _PatternSection(urges: urges),
              const SizedBox(height: 24),
              Text('Recent urge logs',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _RecentLogs(urges: urges),
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (e, _) => const Center(
          child: ErrorBanner(message: 'Could not load urge logs'),
        ),
      ),
    );
  }
}

final _urgesProvider =
    StreamProvider.family<List<UrgeLog>, String>((ref, userId) {
  return ref.watch(urgeRepositoryProvider).watchUserUrges(userId);
});

class _QuickUrgeForm extends ConsumerStatefulWidget {
  const _QuickUrgeForm({required this.userId});

  final String userId;

  @override
  ConsumerState<_QuickUrgeForm> createState() => _QuickUrgeFormState();
}

class _QuickUrgeFormState extends ConsumerState<_QuickUrgeForm> {
  final _locationController = TextEditingController();
  final _moneyController = TextEditingController();
  final _notesController = TextEditingController();
  var _intensity = 5.0;
  var _mood = UrgeMood.stressed;
  var _trigger = UrgeTrigger.boredom;
  var _resisted = true;
  var _saving = false;

  @override
  void dispose() {
    _locationController.dispose();
    _moneyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final moneyText = _moneyController.text.trim();
      final urge = UrgeLog(
        id: '',
        userId: widget.userId,
        createdAt: DateTime.now(),
        intensity: _intensity.round(),
        mood: _mood,
        trigger: _trigger,
        location: _emptyToNull(_locationController.text),
        moneyOnHand: moneyText.isEmpty ? null : double.tryParse(moneyText),
        resisted: _resisted,
        notes: _emptyToNull(_notesController.text),
      );
      final created = await ref.read(urgeRepositoryProvider).createUrge(urge);
      if (!mounted) return;
      _locationController.clear();
      _moneyController.clear();
      _notesController.clear();
      setState(() {
        _intensity = 5;
        _resisted = true;
      });
      await _showCopingPrompt(context, created);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not save urge log');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _showCopingPrompt(BuildContext context, UrgeLog urge) {
    final prompt = _promptForUrge(urge);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prompt.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prompt.message),
            const SizedBox(height: 12),
            Text(
              prompt.technique,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Start now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.flash_on, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick urge log',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Name the moment, then choose the next action.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Intensity: ${_intensity.round()}/10'),
          Slider(
            value: _intensity,
            min: 1,
            max: 10,
            divisions: 9,
            label: _intensity.round().toString(),
            onChanged: (value) => setState(() => _intensity = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<UrgeMood>(
            initialValue: _mood,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: UrgeMood.values
                .map((mood) => DropdownMenuItem(
                      value: mood,
                      child: Text(mood.label),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _mood = value ?? _mood),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UrgeTrigger>(
            initialValue: _trigger,
            decoration: const InputDecoration(labelText: 'Trigger'),
            items: UrgeTrigger.values
                .map((trigger) => DropdownMenuItem(
                      value: trigger,
                      child: Text(trigger.label),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _trigger = value ?? _trigger),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Where are you?',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _moneyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Money to hand',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _resisted,
            contentPadding: EdgeInsets.zero,
            title: const Text('I resisted this urge'),
            onChanged: (value) => setState(() => _resisted = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task),
              label: const Text('Log urge'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.urges});

  final List<UrgeLog> urges;

  @override
  Widget build(BuildContext context) {
    final resisted = urges.where((urge) => urge.resisted).length;
    final rate = urges.isEmpty ? 0 : (resisted / urges.length * 100).round();
    final streak = _resistedStreak(urges);

    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.secondary.withValues(alpha: 0.14),
            child: const Icon(Icons.trending_up, color: AppTheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Control confidence',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  urges.isEmpty
                      ? 'Each log is evidence you can pause before acting.'
                      : '$rate% resisted across ${urges.length} logs. Current streak: $streak.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _resistedStreak(List<UrgeLog> urges) {
    var streak = 0;
    for (final urge in urges) {
      if (!urge.resisted) break;
      streak++;
    }
    return streak;
  }
}

class _RiskPromptCard extends StatelessWidget {
  const _RiskPromptCard({required this.urges});

  final List<UrgeLog> urges;

  @override
  Widget build(BuildContext context) {
    final risky = _riskyUrge(urges);
    final prompt = risky == null ? _starterPrompt() : _promptForUrge(risky);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(prompt.message),
                const SizedBox(height: 8),
                Text(prompt.technique,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  UrgeLog? _riskyUrge(List<UrgeLog> urges) {
    if (urges.isEmpty) return null;
    final nowHour = DateTime.now().hour;
    final matchesNow = urges
        .where((urge) => (urge.createdAt.hour - nowHour).abs() <= 1)
        .toList();
    final candidates = matchesNow.isEmpty ? urges : matchesNow;
    candidates.sort((a, b) => _riskScore(b).compareTo(_riskScore(a)));
    return candidates.first;
  }

  int _riskScore(UrgeLog urge) {
    final moneyRisk = (urge.moneyOnHand ?? 0) >= 20 ? 2 : 0;
    final outcomeRisk = urge.resisted ? 0 : 3;
    return urge.intensity + moneyRisk + outcomeRisk;
  }
}

class _PatternSection extends StatelessWidget {
  const _PatternSection({required this.urges});

  final List<UrgeLog> urges;

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights(urges);
    if (insights.isEmpty) {
      return AppCard(
        child: Text(
          'Log a few urges to spot risky moods, places, triggers, and times.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }
    return Column(
      children: insights
          .map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: ListTile(
                    leading: Icon(_iconForRisk(insight.riskLevel),
                        color: AppTheme.primary),
                    title: Text(insight.title),
                    subtitle: Text(insight.detail),
                    trailing: Text(insight.riskLevel),
                  ),
                ),
              ))
          .toList(),
    );
  }

  List<UrgePatternInsight> _buildInsights(List<UrgeLog> urges) {
    if (urges.isEmpty) return [];
    final insights = <UrgePatternInsight>[];
    final topTrigger = _topBy<UrgeTrigger>(urges, (urge) => urge.trigger);
    final topMood = _topBy<UrgeMood>(urges, (urge) => urge.mood);
    final topHour = _topBy<int>(urges, (urge) => urge.createdAt.hour);
    final cashCount =
        urges.where((urge) => (urge.moneyOnHand ?? 0) >= 20).length;

    if (topTrigger != null) {
      insights.add(UrgePatternInsight(
        title: 'Trigger: ${topTrigger.key.label}',
        detail:
            '${topTrigger.value} of ${urges.length} logs mention this trigger.',
        riskLevel: topTrigger.value >= 3 ? 'High' : 'Watch',
      ));
    }
    if (topMood != null) {
      insights.add(UrgePatternInsight(
        title: 'Mood: ${topMood.key.label}',
        detail: 'This mood appears most often before urges.',
        riskLevel: topMood.value >= 3 ? 'High' : 'Watch',
      ));
    }
    if (topHour != null) {
      insights.add(UrgePatternInsight(
        title: 'Time window: ${_formatHour(topHour.key)}',
        detail: '${topHour.value} logs happened around this time of day.',
        riskLevel: topHour.value >= 3 ? 'High' : 'Watch',
      ));
    }
    if (cashCount > 0) {
      insights.add(UrgePatternInsight(
        title: 'Money to hand',
        detail:
            '$cashCount logs happened with cash or easy spending money available.',
        riskLevel: cashCount >= 3 ? 'High' : 'Watch',
      ));
    }
    return insights.take(4).toList();
  }

  MapEntry<T, int>? _topBy<T>(List<UrgeLog> urges, T Function(UrgeLog) keyFor) {
    final counts = <T, int>{};
    for (final urge in urges) {
      final key = keyFor(urge);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  String _formatHour(int hour) {
    final date = DateTime(2024, 1, 1, hour);
    return DateFormat.j().format(date);
  }

  IconData _iconForRisk(String riskLevel) {
    return riskLevel == 'High' ? Icons.warning_amber : Icons.insights;
  }
}

class _RecentLogs extends StatelessWidget {
  const _RecentLogs({required this.urges});

  final List<UrgeLog> urges;

  @override
  Widget build(BuildContext context) {
    if (urges.isEmpty) {
      return const EmptyState(
        title: 'No urge logs yet',
        subtitle: 'Use the quick log when a gambling urge shows up.',
      );
    }

    return Column(
      children: urges.take(8).map((urge) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              leading: CircleAvatar(child: Text('${urge.intensity}')),
              title: Text('${urge.trigger.label} · ${urge.mood.label}'),
              subtitle: Text(_subtitle(urge)),
              trailing: Icon(
                urge.resisted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: urge.resisted ? AppTheme.secondary : AppTheme.danger,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _subtitle(UrgeLog urge) {
    final parts = [DateFormat.MMMd().add_jm().format(urge.createdAt)];
    if (urge.location != null) {
      parts.add(urge.location!);
    }
    if (urge.moneyOnHand != null) {
      parts.add('GBP ${urge.moneyOnHand!.toStringAsFixed(0)} nearby');
    }
    return parts.join(' - ');
  }
}

CopingPrompt _starterPrompt() {
  return const CopingPrompt(
    title: 'Prompt ready for the next risky moment',
    message:
        'After a few logs, this will match your common time, mood, trigger, and money pattern.',
    technique:
        'For now: delay 10 minutes, move rooms, message someone, then decide.',
  );
}

CopingPrompt _promptForUrge(UrgeLog urge) {
  switch (urge.trigger) {
    case UrgeTrigger.payday:
      return const CopingPrompt(
        title: 'Payday guardrail',
        message:
            'Move spare money out of easy reach before the urge gets louder.',
        technique:
            'Open banking app: transfer, lock card, or set a spend limit.',
      );
    case UrgeTrigger.sportsEvent:
      return const CopingPrompt(
        title: 'Sports trigger spotted',
        message: 'Keep the game, remove the betting path.',
        technique:
            'Watch with someone, mute adverts, and put the phone across the room.',
      );
    case UrgeTrigger.nearVenue:
      return const CopingPrompt(
        title: 'Change the route',
        message: 'Distance helps the urge peak and pass.',
        technique:
            'Cross the street, enter a safe shop, or call a friend while walking away.',
      );
    case UrgeTrigger.aloneAtHome:
      return const CopingPrompt(
        title: 'Interrupt being alone',
        message: 'Connection makes the urge easier to ride out.',
        technique: 'Send a two-word check-in: "urge high".',
      );
    case UrgeTrigger.afterDrink:
      return const CopingPrompt(
        title: 'Alcohol lowers friction',
        message: 'Make gambling harder before making any money decision.',
        technique: 'Put your card away, drink water, and wait 20 minutes.',
      );
    case UrgeTrigger.chasingLosses:
      return const CopingPrompt(
        title: 'Chasing losses alarm',
        message: 'The next bet is not a repair plan.',
        technique:
            'Write the exact loss down, close the app, and tell one person.',
      );
    case UrgeTrigger.advert:
      return const CopingPrompt(
        title: 'Advert trigger',
        message: 'Your attention got pulled; you can pull it back.',
        technique:
            'Block or hide the ad, then do one physical task for 5 minutes.',
      );
    case UrgeTrigger.boredom:
      return const CopingPrompt(
        title: 'Boredom needs a replacement',
        message:
            'The urge is asking for stimulation, not gambling specifically.',
        technique:
            'Start a 10-minute task: shower, walk, game, food, or tidy one surface.',
      );
    case UrgeTrigger.other:
      return CopingPrompt(
        title: 'Urge logged',
        message:
            'Intensity ${urge.intensity}/10 is information, not an instruction.',
        technique: 'Delay, breathe slowly, change location, then choose again.',
      );
  }
}
