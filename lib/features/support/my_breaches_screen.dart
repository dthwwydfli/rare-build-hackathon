import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';

class MyBreachesScreen extends ConsumerWidget {
  const MyBreachesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final breachesAsync = ref.watch(_myBreachesProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('my moments')),
      body: PaperBackground(
        child: breachesAsync.when(
          data: (breaches) {
            if (breaches.isEmpty) {
              return const EmptyState(
                title: 'nothing here — keep going',
                subtitle: 'if a rough moment happens, it shows up here '
                    'so your friends can catch you',
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: breaches.length,
                    itemBuilder: (context, index) {
                      final breach = breaches[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _iconForSignal(breach.signalType),
                              color: AppTheme.inkPlumSoft,
                            ),
                            title: LowercaseText(
                              softSignal(breach.signalType),
                            ),
                            subtitle: LowercaseText(
                              _formatTime(breach.createdAt),
                              style: const TextStyle(
                                color: AppTheme.inkPlumSoft,
                              ),
                            ),
                            trailing: breach.flagged && !breach.acknowledged
                                ? const Icon(Icons.flag,
                                    color: AppTheme.terracotta, size: 20)
                                : breach.acknowledged
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          LowercaseText(
                                            'friends responded',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.lavenderDeep,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          WaxSealCheck(size: 20),
                                        ],
                                      )
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: LowercaseText(
                    'a hard moment doesn\'t erase your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.inkPlumSoft,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) => const Center(
            child: ErrorBanner(message: 'could not load breach history'),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(time);
  }
}

final _myBreachesProvider =
    StreamProvider.family<List<BreachEvent>, String>((ref, userId) {
  return ref.watch(breachRepositoryProvider).watchUserBreaches(userId);
});

IconData _iconForSignal(BreachSignalType type) {
  switch (type) {
    case BreachSignalType.location:
      return Icons.location_on;
    case BreachSignalType.app:
      return Icons.phone_android;
    case BreachSignalType.url:
      return Icons.language;
    case BreachSignalType.payment:
      return Icons.payments;
    case BreachSignalType.manual:
      return Icons.waving_hand;
  }
}
