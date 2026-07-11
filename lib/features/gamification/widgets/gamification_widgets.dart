import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/craft_widgets.dart';

class PointsBadge extends StatelessWidget {
  const PointsBadge({
    super.key,
    required this.points,
    this.showTier = true,
    this.compact = false,
  });

  final int points;
  final bool showTier;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return StatChip(icon: Icons.approval_outlined, label: 'points', value: '$points');
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PointsCard(points: points, compact: compact),
        if (showTier) ...[
          const SizedBox(width: 8),
          TierBadge(points: points),
        ],
      ],
    );
  }
}

class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LowercaseText('streak', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        StreakFlame(streak: streak),
      ],
    );
  }
}

/// Journal-style header for the home screen: today's date, days reclaimed,
/// points stamp-pad, and a solidarity line for the user's circle.
class GamificationHeroCard extends StatelessWidget {
  const GamificationHeroCard({
    super.key,
    required this.points,
    required this.streak,
    this.bestStreak,
    this.groupRank,
    this.groupName,
    this.onViewLeaderboard,
  });

  final int points;
  final int streak;
  final int? bestStreak;
  final int? groupRank;
  final String? groupName;
  final VoidCallback? onViewLeaderboard;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LowercaseText(
          today,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppTheme.inkPlumSoft,
          ),
        ),
        const SizedBox(height: 8),
        DaysReclaimedCard(days: streak, bestDays: bestStreak),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: PointsCard(points: points, compact: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TierBadge(points: points),
                  if (groupRank != null && groupName != null) ...[
                    const SizedBox(height: 8),
                    LowercaseText(
                      'with ${groupName!.toLowerCase()} · #$groupRank',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.inkPlumSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (onViewLeaderboard != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewLeaderboard,
              child: const LowercaseText('see your circle'),
            ),
          ),
        ],
      ],
    );
  }
}
