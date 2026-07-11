import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/milestone_tracker.dart';
import '../../core/utils/screening_prefs.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/enums.dart';
import '../../services/detection/detection_coordinator.dart';
import '../../services/reminders/positive_reminder_service.dart';
import '../gamification/widgets/gamification_widgets.dart';
import '../screening/screening_rescreen_prompt.dart';
import '../../services/screening/screening_reminder_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMilestones();
      _checkRescreenDue();
    });
  }

  Future<void> _checkRescreenDue() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || !mounted) return;
    final status =
        await ref.read(screeningRepositoryProvider).getStatus(user.id);
    if (!mounted) return;
    final show = await shouldShowRescreenPrompt(
      userId: user.id,
      status: status,
    );
    if (show && mounted) {
      await markRescreenPromptShown(user.id);
      const ScreeningReminderService().scheduleDueReminderIfNeeded(
        userId: user.id,
        status: status,
      );
      if (mounted) showRescreenDueDialog(context);
    }
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

    final groupsAsync = ref.watch(userGroupsProvider(user.id));
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
        ],
      ),
      body: PaperBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userGroupsProvider(user.id));
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
                  compact: true,
                ),
                loading: () => const LoadingView(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              const _SafetyActionsCard(),
              const SizedBox(height: 16),
              const _PositiveReminderCard(),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => GamificationPointsRow(
                  points: stats.points,
                  groupRank: groupRank,
                  groupName: firstGroup?.name,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const _ProfessionalHelpCard(),
            ].staggered(context),
          ),
        ),
      ),
    );
  }
}

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

class _SafetyActionsCard extends ConsumerStatefulWidget {
  const _SafetyActionsCard();

  @override
  ConsumerState<_SafetyActionsCard> createState() => _SafetyActionsCardState();
}

class _SafetyActionsCardState extends ConsumerState<_SafetyActionsCard> {
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
        showHelplineSupportSheet(context);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _CrisisHelpTile(onHelp: () => context.push('/crisis')),
          Divider(
            height: 1,
            color: AppTheme.stitchBorder.withValues(alpha: 0.6),
          ),
          _FlagForSupportTile(loading: _loading, onFlag: _flagForSupport),
        ],
      ),
    );
  }
}

class _CrisisHelpTile extends StatelessWidget {
  const _CrisisHelpTile({required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.granola.withValues(alpha: 0.15),
        child: const Icon(Icons.emergency_outlined, color: AppTheme.granola),
      ),
      title: const LowercaseText('need help right now?'),
      subtitle: const LowercaseText(
        'one tap to crisis helplines — Samaritans, GamCare, NHS 111.',
        style: TextStyle(color: AppTheme.inkPlumSoft),
      ),
      trailing: FilledButton(
        onPressed: onHelp,
        style: FilledButton.styleFrom(backgroundColor: AppTheme.granola),
        child: const LowercaseText('help'),
      ),
    );
  }
}

class _FlagForSupportTile extends StatelessWidget {
  const _FlagForSupportTile({
    required this.loading,
    required this.onFlag,
  });

  final bool loading;
  final VoidCallback onFlag;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.granola.withValues(alpha: 0.12),
        child: const Icon(Icons.flag, color: AppTheme.granola),
      ),
      title: const LowercaseText('flag for support'),
      subtitle: const LowercaseText(
        'struggling right now? alert your friends without waiting for detection.',
        style: TextStyle(color: AppTheme.inkPlumSoft),
      ),
      trailing: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton(
              onPressed: onFlag,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.granola),
              child: const LowercaseText('flag'),
            ),
    );
  }
}

class _ProfessionalHelpCard extends StatelessWidget {
  const _ProfessionalHelpCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppTheme.lavenderLight,
          child: Icon(Icons.medical_services_outlined,
              color: AppTheme.lavenderDeep),
        ),
        title: const LowercaseText('need professional help?'),
        subtitle: const LowercaseText(
          'helplines, counselors, and recovery coaches when you need more than a friend.',
          style: TextStyle(color: AppTheme.inkPlumSoft),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/support-hub?segment=help'),
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
