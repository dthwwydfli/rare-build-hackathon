import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/friend_group.dart';
import '../demo/demo_breach_alert.dart';
import 'breach_ui_helpers.dart';

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
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (useMockAuth) const _DemoPaddyPowerButton(),
                    const SizedBox(height: 120),
                    const EmptyState(
                      title: 'no groups yet',
                      subtitle:
                          'join a friend group to be there for each other',
                    ),
                  ],
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (useMockAuth) const _DemoPaddyPowerButton(),
                  if (useMockAuth) const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.lavenderLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flag, color: AppTheme.granola),
                        SizedBox(width: 12),
                        Expanded(
                          child: LowercaseText(
                            'red flags mean a friend broke a commitment or asked for support. tap to send encouragement.',
                            style: TextStyle(color: AppTheme.inkPlumSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...groups.map((group) {
                    return _GroupBreachesSection(
                      group: group,
                      currentUserId: user.id,
                    );
                  }),
                ],
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

/// Count of friend breaches across all groups that still need support.
final unreadAlertsCountProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0;

  final groups = ref.watch(_groupsProvider(user.id)).valueOrNull ?? [];
  var count = 0;
  for (final group in groups) {
    final breaches =
        ref.watch(_groupBreachesProvider(group.id)).valueOrNull ?? [];
    count +=
        breaches.where((b) => b.userId != user.id && b.needsSupport).length;
  }
  return count;
});

class _DemoPaddyPowerButton extends StatelessWidget {
  const _DemoPaddyPowerButton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppTheme.lavenderLight,
          child: Icon(
            Icons.notifications_active_outlined,
            color: AppTheme.lavenderDeep,
          ),
        ),
        title: const LowercaseText('demo: paddy power alert'),
        subtitle: const LowercaseText(
          'preview the notification you\'d get when entering paddy power.',
          style: TextStyle(color: AppTheme.inkPlumSoft),
        ),
        trailing: FilledButton(
          onPressed: () => showDemoPaddyPowerAlert(context),
          child: const LowercaseText('show'),
        ),
      ),
    );
  }
}

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
                  'all quiet and everyone\'s doing okay',
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
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.lavenderLight,
                            child: Icon(
                              breachSignalIcon(breach.signalType),
                              color: AppTheme.lavenderDeep,
                            ),
                          ),
                          if (breach.needsSupport)
                            const Positioned(
                              right: -2,
                              top: -2,
                              child: Icon(
                                Icons.flag,
                                color: AppTheme.granola,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        breach.userName ?? 'group member',
                        style: TextStyle(
                          fontWeight: breach.needsSupport
                              ? FontWeight.bold
                              : breach.acknowledged
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                        ),
                      ),
                      subtitle: LowercaseText(
                        '${softSignal(breach.signalType)} · ${formatRelativeTime(breach.createdAt)}',
                        style: const TextStyle(color: AppTheme.inkPlumSoft),
                      ),
                      trailing: breach.acknowledged
                          ? const WaxSealCheck(size: 22)
                          : const Icon(Icons.fiber_manual_record,
                              color: AppTheme.granola, size: 12),
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
          error: (e, _) =>
              const ErrorBanner(message: 'could not load breaches'),
        ),
      ],
    );
  }
}

final _groupBreachesProvider =
    StreamProvider.family<List<BreachEvent>, String>((ref, groupId) {
  return ref.watch(breachRepositoryProvider).watchGroupBreaches(groupId);
});
