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
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';
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

    final groupsAsync = ref.watch(_userGroupsProvider(user.id));
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
            ref.invalidate(_userGroupsProvider(user.id));
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
                ),
                loading: () => const LoadingView(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const _PositiveReminderCard(),
              const SizedBox(height: 16),
              const _FlagForSupportCard(),
            ].staggered(context),
          ),
        ),
      ),
    );
  }
}

final _userGroupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
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
                style:
                    FilledButton.styleFrom(backgroundColor: AppTheme.granola),
                child: const LowercaseText('flag'),
              ),
      ),
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
