import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';
import '../../domain/models/support_message.dart';
import '../../services/detection/detection_coordinator.dart';
import '../../services/reminders/positive_reminder_service.dart';
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
<<<<<<< HEAD
      body: PaperBackground(
        child: RefreshIndicator(
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
                  bestStreak: stats.bestStreak,
                  groupRank: groupRank,
                  groupName: firstGroup?.name,
                  onViewLeaderboard: () => context.go('/leaderboard'),
=======
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_userCommitmentsProvider(user.id));
          ref.invalidate(_userGroupsProvider(user.id));
          ref.invalidate(_userSupportProvider(user.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PositiveReminderCard(),
            const SizedBox(height: 16),
            _FlagForSupportCard(),
            const SizedBox(height: 16),
            _RecoveryToolsRow(),
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
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add friends so they can support you when commitments are at risk.',
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/groups/new'),
                          child: const Text('Add'),
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
            Text('Active commitments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            commitmentsAsync.when(
              data: (commitments) => _CommitmentsSummary(commitments: commitments),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorBanner(message: 'Could not load commitments'),
            ),
            const SizedBox(height: 24),
            Text('Your groups', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            groupsAsync.when(
              data: (groups) => _GroupsSummary(groups: groups),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorBanner(message: 'Could not load groups'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent support', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/my-breaches'),
                  child: const Text('My breaches'),
>>>>>>> ba2564f (feat: block access and money feature)
                ),
                loading: () => const LoadingView(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const _PositiveReminderCard(),
              const SizedBox(height: 16),
              const _FlagForSupportCard(),
              const SizedBox(height: 20),
              const Center(child: OrnamentalDivider()),
              const SizedBox(height: 20),
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
                        border: Border.all(
                          color: AppTheme.lavender.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppTheme.lavender),
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
              const LowercaseText(
                'active goals',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              commitmentsAsync.when(
                data: (commitments) => _CommitmentsSummary(
                  commitments: commitments,
                  streak: statsAsync.valueOrNull?.currentStreak ?? 0,
                ),
                loading: () => const LoadingView(),
                error: (e, _) =>
                    const ErrorBanner(message: 'could not load goals'),
              ),
              const SizedBox(height: 20),
              const Center(child: OrnamentalDivider()),
              const SizedBox(height: 20),
              const LowercaseText(
                'your groups',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              groupsAsync.when(
                data: (groups) =>
                    _GroupsSummary(groups: groups, userId: user.id),
                loading: () => const LoadingView(),
                error: (e, _) =>
                    const ErrorBanner(message: 'could not load groups'),
              ),
              const SizedBox(height: 20),
              const Center(child: OrnamentalDivider()),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LowercaseText(
                    'notes from friends',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () => context.push('/my-breaches'),
                    child: const LowercaseText('my moments'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              supportAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const LowercaseText(
                      'no notes yet — when friends reach out, their words land here.',
                      style: TextStyle(color: AppTheme.inkPlumSoft),
                    );
                  }
                  return Column(
                    children: messages.take(3).map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.favorite,
                                color: AppTheme.terracotta),
                            title: Text(m.message),
                            subtitle: LowercaseText(
                              m.fromUserName ?? 'a friend',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.inkPlumSoft,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LoadingView(),
                error: (e, _) => const ErrorBanner(
                  message: 'could not load support messages',
                ),
              ),
            ].staggered(context),
          ),
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

class _PositiveReminderCard extends ConsumerWidget {
  const _PositiveReminderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(currentPositiveReminderProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lavenderDeep.withValues(alpha: 0.9),
            AppTheme.lavender,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LowercaseText(
                  'positive reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagForSupportCard extends ConsumerStatefulWidget {
  const _FlagForSupportCard();

  @override
  ConsumerState<_FlagForSupportCard> createState() =>
      _FlagForSupportCardState();
}

class _FlagForSupportCardState extends ConsumerState<_FlagForSupportCard> {
  bool _loading = false;

  Future<void> _flagForSupport() async {
    setState(() => _loading = true);
    try {
      await ref.read(detectionCoordinatorProvider).emitManualBreach(
            signalType: BreachSignalType.manual,
            metadata: {
              'note': 'Flagged for support — reaching out to my circle',
              'selfFlagged': true,
            },
          );
      if (mounted) {
        showAppSnackBar(
          context,
          'support circle flagged — friends will be alerted',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppTheme.terracotta.withValues(alpha: 0.12),
          child: const Icon(Icons.flag, color: AppTheme.terracotta),
        ),
        title: const LowercaseText('flag for support'),
        subtitle: const LowercaseText(
          'struggling right now? alert your friends without waiting for detection.',
          style: TextStyle(color: AppTheme.inkPlumSoft),
        ),
        trailing: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: _flagForSupport,
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.terracotta),
                child: const LowercaseText('flag'),
              ),
      ),
    );
  }
}

<<<<<<< HEAD
=======
class _RecoveryToolsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          onTap: () => context.push('/tools/blocks'),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primary),
            ),
            title: const Text(
              'Block access & money',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'GAMSTOP, bank blocks, app blocker, spending delays',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          onTap: () => context.push('/urges/log'),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
              child: const Icon(Icons.psychology_outlined, color: AppTheme.primary),
            ),
            title: const Text(
              'Log an urge',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              '30-second CBT log — spot triggers, get coping prompts',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/urges/insights'),
            child: const Text('View urge patterns'),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.flag_outlined,
                label: 'Commitments',
                onTap: () => context.push('/commitments'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.group_outlined,
                label: 'Groups',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.inbox_outlined,
                label: 'Alerts',
                onTap: () => context.push('/support'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.person_search_outlined,
          label: 'Find people on the app',
          onTap: () => context.push('/people/find'),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

>>>>>>> ba2564f (feat: block access and money feature)
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 6),
          child: ContractCard(
            title: c.title,
            stamp: const StampBadge.active(size: 48),
            onTap: () => context.push('/commitments/${c.id}/edit'),
            child: Row(
              children: [
                PatchChip(label: c.type.label, icon: _iconForType(c.type)),
                if (streak > 0) ...[
                  const SizedBox(width: 8),
                  StreakFlame(streak: streak),
                ],
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppTheme.inkPlumSoft),
              ],
            ),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.group_outlined,
                  color: AppTheme.lavenderDeep),
              title: Text(g.name),
              subtitle: LowercaseText(
                '${g.memberIds.length} walking together${rank != null ? ' · you\'re #$rank' : ''}',
                style: const TextStyle(color: AppTheme.inkPlumSoft),
              ),
              onTap: () => context.push('/groups'),
            ),
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
