import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/urge_log.dart';
import '../../services/urges/coping_prompt_service.dart';

class UrgeLogScreen extends ConsumerStatefulWidget {
  const UrgeLogScreen({super.key});

  @override
  ConsumerState<UrgeLogScreen> createState() => _UrgeLogScreenState();
}

class _UrgeLogScreenState extends ConsumerState<UrgeLogScreen> {
  int _intensity = 6;
  UrgeMood _mood = UrgeMood.stressed;
  UrgeTrigger _trigger = UrgeTrigger.boredom;
  bool _resisted = true;
  bool _saving = false;

  final _locationController = TextEditingController();
  final _moneyController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _moneyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(urgeRepositoryProvider).createUrge(
            UrgeLog(
              id: '',
              userId: user.id,
              createdAt: DateTime.now(),
              intensity: _intensity,
              mood: _mood,
              trigger: _trigger,
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              moneyOnHand: double.tryParse(_moneyController.text),
              resisted: _resisted,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );

      final prompt = CopingPromptService().promptForUrge(
        trigger: _trigger,
        mood: _mood,
      );

      final highRisk = _intensity >= 8 ||
          _mood == UrgeMood.sad ||
          _mood == UrgeMood.stressed;

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(prompt.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prompt.message),
              const SizedBox(height: 12),
              Chip(
                label: Text(prompt.technique),
                backgroundColor: AppTheme.accent,
              ),
              if (highRisk) ...[
                const SizedBox(height: 16),
                const Text(
                  'this feels intense — you can talk to someone trained right now.',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ],
          ),
          actions: [
            if (highRisk)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/crisis');
                },
                child: const Text('Talk to someone now'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/urges/insights');
              },
              child: const Text('See patterns'),
            ),
          ],
        ),
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Could not save urge log');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = CopingPromptService().promptForUrge(
      trigger: _trigger,
      mood: _mood,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quick urge log')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Log urges in under 30 seconds. CBT research shows tracking builds '
            'the confidence that you can control them.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${prompt.title}: ${prompt.message}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('How strong is the urge? ($_intensity/10)',
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_intensity',
            onChanged: (v) => setState(() => _intensity = v.round()),
          ),
          const SizedBox(height: 16),
          Text('Mood', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UrgeMood.values.map((m) {
              return ChoiceChip(
                label: Text(m.label),
                selected: _mood == m,
                onSelected: (_) => setState(() => _mood = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Trigger', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UrgeTrigger.values.map((t) {
              return ChoiceChip(
                label: Text(t.label),
                selected: _trigger == t,
                onSelected: (_) => setState(() => _trigger = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Where are you? (optional)',
              hintText: 'Home, pub, near betting shop...',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _moneyController,
            decoration: const InputDecoration(
              labelText: 'Money on hand (£)',
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I resisted this urge'),
            subtitle: const Text('Logging resisted urges builds confidence'),
            value: _resisted,
            onChanged: (v) => setState(() => _resisted = v),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log urge & get coping prompt'),
          ),
        ],
      ),
    );
  }
}
