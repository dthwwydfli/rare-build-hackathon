import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';
import '../../domain/models/support_message.dart';
import '../gamification/widgets/gamification_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMilestones());
  }

  Future<void> _checkMilestones() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !mounted) return;
    final stats = await ref.read(userStatsProvider(user.id).future);
    if (!mounted) return;
    await MilestoneTracker.checkAndNotify(
      points: stats.points,
      currentStreak: stats.currentStreak,
      onMilestone: (message) {
        if (mounted) showAppSnackBar(context, message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const LoadingView();

    final commitmentsAsync = ref.watch(_userCommitmentsProvider(user.id));
    final groupsAsync = ref.watch(_userGroupsProvider(user.id));
    final supportAsync = ref.watch(_userSupportProvider(user.id));
    final statsAsync = ref.watch(userStatsProvider(user.id));

    final firstGroup = groupsAsync.valueOrNull?.firstOrNull;
    final groupRankAsync = firstGroup != null
        ? ref.watch(groupLeaderboardProvider(firstGroup.id))
        : null;

    int? groupRank;
    if (groupRankAsync != null) {
      groupRank = groupRankAsync.valueOrNull
          ?.where((e) => e.userId == user.id)
          .map((e) => e.rank)
          .firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(
        title: LowercaseText('hi, ${user.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/permissions'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_userCommitmentsProvider(user.id));
          ref.invalidate(_userGroupsProvider(user.id));
          ref.invalidate(_userSupportProvider(user.id));
          ref.invalidate(userStatsProvider(user.id));
          if (firstGroup != null) {
            ref.invalidate(groupLeaderboardProvider(firstGroup.id));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              data: (stats) => GamificationHeroCard(
                points: stats.points,
                streak: stats.currentStreak,
                groupRank: groupRank,
                groupName: firstGroup?.name,
                onViewLeaderboard: () => context.go('/leaderboard'),
              ),
              loading: () => const LoadingView(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 16),
            commitmentsAsync.when(
              data: (commitments) {
                final groups = groupsAsync.valueOrNull ?? [];
                if (commitments.isNotEmpty && groups.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lavenderLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lavender.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.lavender),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: LowercaseText(
                            'add friends so they can support you when goals are at risk',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/groups/new'),
                          child: const LowercaseText('add'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const LowercaseText('active goals', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            commitmentsAsync.when(
              data: (commitments) => _CommitmentsSummary(
                commitments: commitments,
                streak: statsAsync.valueOrNull?.currentStreak ?? 0,
              ),
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorBanner(message: 'could not load goals'),
            ),
            const SizedBox(height: 24),
            const LowercaseText('your groups', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            groupsAsync.when(
              data: (groups) => _GroupsSummary(groups: groups, userId: user.id),
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorBanner(message: 'could not load groups'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LowercaseText('recent support', style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => context.push('/my-breaches'),
                  child: const LowercaseText('my breaches'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            supportAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return LowercaseText(
                    'no support messages yet',
                    style: TextStyle(color: AppTheme.granolaDark.withValues(alpha: 0.7)),
                  );
                }
                return Column(
                  children: messages.take(3).map((m) {
                    return AppCard(
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: AppTheme.lavender),
                        title: Text(m.message),
                        subtitle: Text(m.fromUserName ?? 'a friend'),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) => const ErrorBanner(message: 'could not load support messages'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dev/simulator'),
        icon: const Icon(Icons.science_outlined),
        label: const LowercaseText('demo breach'),
      ),
    );
  }
}

final _userCommitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});

final _userGroupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});

final _userSupportProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, userId) {
  return ref.watch(breachRepositoryProvider).watchSupportForUser(userId);
});

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.flag_outlined,
            label: 'goals',
            onTap: () => context.push('/commitments'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.group_outlined,
            label: 'groups',
            onTap: () => context.push('/groups'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.inbox_outlined,
            label: 'alerts',
            onTap: () => context.push('/support'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          LowercaseText(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CommitmentsSummary extends StatelessWidget {
  const _CommitmentsSummary({
    required this.commitments,
    required this.streak,
  });

  final List<Commitment> commitments;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final active = commitments.where((c) => c.active).toList();
    if (active.isEmpty) {
      return EmptyState(
        title: 'no goals yet',
        subtitle: 'create your first goal to get started',
        action: ElevatedButton(
          onPressed: () => context.push('/commitments/new'),
          child: const LowercaseText('create goal'),
        ),
      );
    }
    return Column(
      children: active.take(3).map((c) {
        return AppCard(
          child: ListTile(
            leading: Icon(_iconForType(c.type)),
            title: Text(c.title),
            subtitle: Row(
              children: [
                LowercaseText(c.type.label),
                if (streak > 0) ...[
                  const SizedBox(width: 8),
                  StreakFlame(streak: streak),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/commitments/${c.id}/edit'),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconForType(CommitmentType type) {
    switch (type) {
      case CommitmentType.location:
        return Icons.location_on_outlined;
      case CommitmentType.spending:
        return Icons.payments_outlined;
      case CommitmentType.online:
        return Icons.phone_android_outlined;
    }
  }
}

class _GroupsSummary extends ConsumerWidget {
  const _GroupsSummary({required this.groups, required this.userId});

  final List<FriendGroup> groups;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groups.isEmpty) {
      return EmptyState(
        title: 'no friend groups',
        subtitle: 'invite trusted friends to support you',
        action: ElevatedButton(
          onPressed: () => context.push('/groups/new'),
          child: const LowercaseText('create group'),
        ),
      );
    }
    return Column(
      children: groups.map((g) {
        final rankAsync = ref.watch(groupLeaderboardProvider(g.id));
        final rank = rankAsync.valueOrNull
            ?.where((e) => e.userId == userId)
            .map((e) => e.rank)
            .firstOrNull;
        return AppCard(
          child: ListTile(
            leading: const Icon(Icons.group),
            title: Text(g.name),
            subtitle: LowercaseText(
              '${g.memberIds.length} members · code: ${g.inviteCode}${rank != null ? ' · rank #$rank' : ''}',
            ),
            onTap: () => context.push('/groups'),
          ),
        );
      }).toList(),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
