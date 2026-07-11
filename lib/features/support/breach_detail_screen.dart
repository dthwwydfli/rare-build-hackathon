import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/widgets/app_widgets.dart';
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
        if (showFirst) {
          await MilestoneTracker.markSeen('first_support');
          showAppSnackBar(context, '+5 points for being a good friend');
        } else {
          showAppSnackBar(context, '+5 points — support sent');
        }
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
      body: breachesAsync.when(
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
              Card(
                color: AppTheme.danger.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breach.userName ?? 'friend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(breach.summary),
                      const SizedBox(height: 4),
                      LowercaseText(
                        '${breach.signalType.label} · ${_formatTime(breach.createdAt)}',
                        style: TextStyle(color: AppTheme.granolaDark.withValues(alpha: 0.8)),
                      ),
                      breacherStatsAsync.when(
                        data: (stats) => Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              StatChip(
                                icon: Icons.emoji_events_outlined,
                                label: 'points',
                                value: '${stats.points}',
                              ),
                              const SizedBox(width: 8),
                              StreakFlame(streak: stats.currentStreak),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const LowercaseText('quick messages', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetMessages.map((preset) {
                  return ActionChip(
                    label: Text(preset.$1, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SupportMessageType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'message type'),
                items: SupportMessageType.values
                    .map((t) => DropdownMenuItem(value: t, child: LowercaseText(t.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _sending ? null : () => _sendSupport(breach!),
                child: _sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const LowercaseText('send support'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: ErrorBanner(message: 'could not load breach')),
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
