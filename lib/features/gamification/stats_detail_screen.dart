import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import 'widgets/gamification_widgets.dart';

class StatsDetailScreen extends ConsumerWidget {
  const StatsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final statsAsync = ref.watch(userStatsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('your journey')),
      body: PaperBackground(
        child: statsAsync.when(
          data: (stats) {
            final nextThreshold = stats.points >= 1200
                ? null
                : stats.points >= 1100
                    ? 1200
                    : stats.points >= 1000
                        ? 1100
                        : 1000;
            final prevThreshold = nextThreshold == null
                ? 1200
                : nextThreshold - 100;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DaysReclaimedCard(
                  days: stats.currentStreak,
                  bestDays: stats.bestStreak,
                ),
                const SizedBox(height: 16),
                PointsBadge(points: stats.points),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nextThreshold != null) ...[
                        LowercaseText(
                          'stitching toward ${softTierLabel(nextThreshold)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkPlum,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StitchProgress(
                          value: (stats.points - prevThreshold) / 100,
                        ),
                        const SizedBox(height: 6),
                        LowercaseText(
                          '${nextThreshold - stats.points} points to go',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.inkPlumSoft,
                          ),
                        ),
                      ] else
                        const LowercaseText(
                          'gardener — the whole path, stitched.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (stats.lastCleanDate != null) ...[
                        LowercaseText(
                          'last clean day: ${stats.lastCleanDate!.toLocal().toString().split(' ').first}',
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (stats.lastBreachDate != null)
                        LowercaseText(
                          'last rough moment: ${stats.lastBreachDate!.toLocal().toString().split(' ').first}',
                          style:
                              const TextStyle(color: AppTheme.inkPlumSoft),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const LoadingView(),
          error: (_, __) => const ErrorBanner(message: 'could not load stats'),
        ),
      ),
    );
  }
}
