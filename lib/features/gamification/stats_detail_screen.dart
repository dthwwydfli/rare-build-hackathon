import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_widgets.dart';
import 'widgets/gamification_widgets.dart';

class StatsDetailScreen extends ConsumerWidget {
  const StatsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final statsAsync = ref.watch(userStatsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('your stats')),
      body: statsAsync.when(
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PointsBadge(points: stats.points),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LowercaseText('current streak'),
                    const SizedBox(height: 8),
                    StreakBanner(streak: stats.currentStreak),
                    const SizedBox(height: 16),
                    LowercaseText('best streak: ${stats.bestStreak}'),
                    if (stats.lastCleanDate != null) ...[
                      const SizedBox(height: 8),
                      LowercaseText(
                        'last clean day: ${stats.lastCleanDate!.toLocal().toString().split(' ').first}',
                      ),
                    ],
                    if (stats.lastBreachDate != null) ...[
                      const SizedBox(height: 8),
                      LowercaseText(
                        'last breach: ${stats.lastBreachDate!.toLocal().toString().split(' ').first}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorBanner(message: 'could not load stats'),
      ),
    );
  }
}
