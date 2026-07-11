import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
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
      appBar: AppBar(title: const Text('My breach history')),
      body: breachesAsync.when(
        data: (breaches) {
          if (breaches.isEmpty) {
            return const EmptyState(
              title: 'No breaches recorded',
              subtitle: 'When detection triggers, your history appears here',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: breaches.length,
            itemBuilder: (context, index) {
              final breach = breaches[index];
              return AppCard(
                child: ListTile(
                  leading: Icon(
                    _iconForSignal(breach.signalType),
                    color: AppTheme.danger,
                  ),
                  title: Text(breach.summary),
                  subtitle: Text(
                    '${breach.signalType.label} · ${_formatTime(breach.createdAt)}',
                  ),
                  trailing: breach.acknowledged
                      ? const Icon(Icons.check, color: Colors.green, size: 20)
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => const Center(
          child: ErrorBanner(message: 'Could not load breach history'),
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
      return Icons.warning_amber;
  }
}
