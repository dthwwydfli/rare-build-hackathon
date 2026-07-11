import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/support_message.dart';

const _presetMessages = [
  ("You've got this — I'm here for you", SupportMessageType.encouragement),
  ("Want to talk? I'm free right now", SupportMessageType.checkIn),
  ('Call me if you need support', SupportMessageType.callOffer),
  ('Proud of you for being accountable', SupportMessageType.encouragement),
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
      if (mounted) {
        showAppSnackBar(context, 'Support message sent');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not send message. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final breachesAsync = ref.watch(_groupBreachesProvider(widget.groupId));
    final supportAsync = ref.watch(_breachSupportProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Social support')),
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
            return const Center(child: Text('Breach not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (breach.needsSupport)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flag, color: AppTheme.danger),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Flagged — this friend may need your support right now.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breach.userName ?? 'Friend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(breach.summary),
                      const SizedBox(height: 4),
                      Text(
                        '${breach.signalType.label} · ${_formatTime(breach.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Support from your circle',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              supportAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Text(
                      'No one has responded yet — be the first to reach out.',
                      style: TextStyle(color: Colors.grey.shade600),
                    );
                  }
                  return Column(
                    children: messages.map((m) {
                      return AppCard(
                        child: ListTile(
                          leading: const Icon(Icons.favorite, color: AppTheme.danger),
                          title: Text(m.message),
                          subtitle: Text(
                            '${m.fromUserName ?? 'Friend'} · ${m.type.label}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              Text('Quick messages', style: Theme.of(context).textTheme.titleSmall),
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
                  labelText: 'Your message',
                  hintText: 'Write something supportive...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SupportMessageType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Message type'),
                items: SupportMessageType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
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
                    : const Text('Send support'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: ErrorBanner(message: 'Could not load breach'),
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

final _breachSupportProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, breachEventId) {
  return ref.watch(breachRepositoryProvider).watchSupportForBreach(breachEventId);
});
