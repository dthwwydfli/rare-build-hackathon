import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';

class SupportInboxScreen extends ConsumerWidget {
  const SupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final groupsAsync = ref.watch(_groupsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('alerts')),
      body: PaperBackground(
        child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_groupsProvider(user.id));
        },
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'no groups yet',
                    subtitle: 'join a friend group to be there for each other',
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: groups.map((group) {
                return _GroupBreachesSection(
                  group: group,
                  currentUserId: user.id,
                );
              }).toList(),
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) => ListView(
            children: const [
              SizedBox(height: 48),
              Padding(
                padding: EdgeInsets.all(16),
                child: ErrorBanner(message: 'could not load alerts'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

final _groupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});

class _GroupBreachesSection extends ConsumerWidget {
  const _GroupBreachesSection({
    required this.group,
    required this.currentUserId,
  });

  final FriendGroup group;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breachesAsync = ref.watch(_groupBreachesProvider(group.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            group.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        breachesAsync.when(
          data: (breaches) {
            final relevant = breaches
                .where((b) => b.userId != currentUserId)
                .take(10)
                .toList();
            if (relevant.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LowercaseText(
                  'all quiet — everyone\'s doing okay',
                  style: TextStyle(color: AppTheme.inkPlumSoft),
                ),
              );
            }
            return Column(
              children: relevant.map((breach) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => context.push(
                      '/breach/${breach.id}?groupId=${group.id}',
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.lavenderLight,
                        child: Icon(
                          _iconForSignal(breach.signalType),
                          color: AppTheme.lavenderDeep,
                        ),
                      ),
                      title: Text(
                        breach.userName ?? 'group member',
                        style: TextStyle(
                          fontWeight: breach.acknowledged
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: LowercaseText(
                        '${softSignal(breach.signalType)} · ${_formatTime(breach.createdAt)}',
                        style: const TextStyle(color: AppTheme.inkPlumSoft),
                      ),
                      trailing: breach.acknowledged
                          ? const WaxSealCheck(size: 22)
                          : const Icon(Icons.fiber_manual_record,
                              color: AppTheme.terracotta, size: 12),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => const ErrorBanner(message: 'could not load breaches'),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(time);
  }
}

final _groupBreachesProvider =
    StreamProvider.family<List<BreachEvent>, String>((ref, groupId) {
  return ref.watch(breachRepositoryProvider).watchGroupBreaches(groupId);
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
