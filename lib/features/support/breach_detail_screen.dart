import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/support_message.dart';

const _presetMessages = [
  ("You've got this — I'm here for you", SupportMessageType.encouragement),
  ("Want to talk? I'm free right now", SupportMessageType.checkIn),
  ('Call me if you need support', SupportMessageType.callOffer),
];

class BreachDetailScreen extends ConsumerStatefulWidget {
  const BreachDetailScreen({
    super.key,
    required this.eventId,
    required this.groupId,
  });

  final String eventId;
  final String groupId;

  @override
  ConsumerState<BreachDetailScreen> createState() => _BreachDetailScreenState();
}

class _BreachDetailScreenState extends ConsumerState<BreachDetailScreen> {
  final _messageController = TextEditingController();
  SupportMessageType _selectedType = SupportMessageType.encouragement;
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendSupport(BreachEvent breach) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(breachRepositoryProvider).sendSupport(
            SupportMessage(
              id: '',
              breachEventId: breach.id,
              fromUserId: user.id,
              toUserId: breach.userId,
              message: message,
              type: _selectedType,
              createdAt: DateTime.now(),
              fromUserName: user.displayName,
            ),
          );
      await ref.read(breachRepositoryProvider).acknowledgeBreach(breach.id);
      await ref.read(gamificationRepositoryProvider).applySupportBonus(user.id);

      if (mounted) {
        final showFirst = await MilestoneTracker.shouldShow('first_support');
        if (!mounted) return;
        if (showFirst) {
          await MilestoneTracker.markSeen('first_support');
        }
        if (!mounted) return;
        // A quiet seal moment before returning — one-shot, calm.
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            Future.delayed(const Duration(milliseconds: 900), () {
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            });
            return Center(
              child: const WaxSealCheck(size: 72).sealIn(dialogContext),
            );
          },
        );
        if (!mounted) return;
        showAppSnackBar(context, '+5 — thanks for showing up');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'could not send message. please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breachesAsync = ref.watch(_groupBreachesProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('send support')),
      body: PaperBackground(
        child: breachesAsync.when(
        data: (breaches) {
          BreachEvent? breach;
          for (final b in breaches) {
            if (b.id == widget.eventId) {
              breach = b;
              break;
            }
          }
          if (breach == null) {
            return const Center(child: LowercaseText('breach not found'));
          }

          final breacherStatsAsync =
              ref.watch(userStatsProvider(breach.userId));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TactileCard(
                useStitch: true,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LowercaseText(
                      '${breach.userName ?? 'a friend'} hit a rough moment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    LowercaseText(
                      '${softSignal(breach.signalType)} · ${_formatTime(breach.createdAt)}',
                      style: const TextStyle(color: AppTheme.inkPlumSoft),
                    ),
                    const SizedBox(height: 12),
                    const LowercaseText(
                      'showing up now is what this app is for.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.lavenderDeep,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    breacherStatsAsync.when(
                      data: (stats) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: LowercaseText(
                          '${stats.bestStreak} days reclaimed so far — that doesn\'t go away.',
                          style: const TextStyle(
                            color: AppTheme.sageDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const LowercaseText('quick notes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetMessages.map((preset) {
                  final selected = _messageController.text == preset.$1;
                  return PatchChip(
                    label: preset.$1,
                    selected: selected,
                    tilted: true,
                    onTap: () {
                      setState(() {
                        _messageController.text = preset.$1;
                        _selectedType = preset.$2;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'your message',
                  hintText: 'write something supportive...',
                ),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _sending ? null : () => _sendSupport(breach!),
                icon: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.favorite, size: 18),
                label: const LowercaseText('send support'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: ErrorBanner(message: 'could not load breach')),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat.MMMd().format(time);
  }
}

final _groupBreachesProvider =
    StreamProvider.family<List<BreachEvent>, String>((ref, groupId) {
  return ref.watch(breachRepositoryProvider).watchGroupBreaches(groupId);
});
