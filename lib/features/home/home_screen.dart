import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/widgets/app_widgets.dart';
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
                ),
                loading: () => const LoadingView(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const _PositiveReminderCard(),
              const SizedBox(height: 16),
              const _FlagForSupportCard(),
              const SizedBox(height: 16),
              const _QuickActions(),
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
                        border: Border.all(
                          color: AppTheme.lavenderDeep.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.lavenderDeep,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: LowercaseText(
                              'add friends so they can support you when goals are at risk.',
                              style: TextStyle(color: AppTheme.inkPlumSoft),
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
              LowercaseText(
                'active goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              commitmentsAsync.when(
                data: (commitments) =>
                    _CommitmentsSummary(commitments: commitments),
                loading: () => const LoadingView(),
                error: (_, __) =>
                    const ErrorBanner(message: 'could not load goals'),
              ),
              const SizedBox(height: 24),
              LowercaseText(
                'your groups',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              groupsAsync.when(
                data: (groups) => _GroupsSummary(groups: groups),
                loading: () => const LoadingView(),
                error: (_, __) =>
                    const ErrorBanner(message: 'could not load groups'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LowercaseText(
                    'recent support',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push('/my-breaches'),
                    child: const LowercaseText('my moments'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              supportAsync.when(
                data: (messages) => _RecentSupport(messages: messages),
                loading: () => const LoadingView(),
                error: (_, __) =>
                    const ErrorBanner(message: 'could not load support'),
              ),
            ].staggered(context),
          ),
        ),
      ),
    );
  }
}

final _userCommitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
      return ref
          .watch(commitmentRepositoryProvider)
          .watchUserCommitments(userId);
    });

final _userGroupsProvider = StreamProvider.family<List<FriendGroup>, String>((
  ref,
  userId,
) {
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
      await ref
          .read(detectionCoordinatorProvider)
          .emitManualBreach(
            signalType: BreachSignalType.manual,
            metadata: {
              'note': 'Flagged for support - reaching out to my circle',
              'selfFlagged': true,
            },
          );
      if (mounted) {
        showAppSnackBar(
          context,
          'support circle flagged - friends will be alerted',
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
          backgroundColor: AppTheme.granola.withValues(alpha: 0.12),
          child: const Icon(Icons.flag, color: AppTheme.granola),
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
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.granola,
                ),
                child: const LowercaseText('flag'),
              ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
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
                icon: Icons.psychology_alt_outlined,
                label: 'log urge',
                onTap: () => context.push('/urges/log'),
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
        ),
        const SizedBox(height: 12),
        Row(
          children: [
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
                icon: Icons.person_search_outlined,
                label: 'find people',
                onTap: () => context.push('/people/find'),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          LowercaseText(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CommitmentsSummary extends StatelessWidget {
  const _CommitmentsSummary({required this.commitments});

  final List<Commitment> commitments;

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
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconForType(c.type)),
              title: LowercaseText(c.title),
              subtitle: LowercaseText(c.type.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/commitments/${c.id}/edit'),
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

class _GroupsSummary extends StatelessWidget {
  const _GroupsSummary({required this.groups});

  final List<FriendGroup> groups;

  @override
  Widget build(BuildContext context) {
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
      children: groups.take(3).map((g) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.group),
              title: LowercaseText(g.name),
              subtitle: LowercaseText(
                '${g.memberIds.length} members - code: ${g.inviteCode}',
              ),
              onTap: () => context.push('/groups'),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RecentSupport extends StatelessWidget {
  const _RecentSupport({required this.messages});

  final List<SupportMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const LowercaseText(
        'no support messages yet',
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
              leading: const Icon(Icons.favorite, color: AppTheme.danger),
              title: LowercaseText(m.message),
              subtitle: LowercaseText(m.fromUserName ?? 'a friend'),
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
