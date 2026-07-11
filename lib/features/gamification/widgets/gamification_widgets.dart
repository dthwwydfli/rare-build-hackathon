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

class GamificationHeroCard extends StatelessWidget {
  const GamificationHeroCard({
    super.key,
    required this.points,
    required this.streak,
    this.bestStreak,
    this.groupRank,
    this.groupName,
    this.compact = false,
  });

  final int points;
  final int streak;
  final int? bestStreak;
  final int? groupRank;
  final String? groupName;

  /// When true, shows a dense streak card with inline points below the streak.
  final bool compact;

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
        DaysReclaimedCard(
          days: streak,
          bestDays: compact ? null : bestStreak,
          dense: compact,
          points: compact ? points : null,
          groupRank: compact ? groupRank : null,
          groupName: compact ? groupName : null,
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          GamificationPointsRow(
            points: points,
            groupRank: groupRank,
            groupName: groupName,
          ),
        ],
      ],
    );
  }
}

class GamificationPointsRow extends StatelessWidget {
  const GamificationPointsRow({
    super.key,
    required this.points,
    this.groupRank,
    this.groupName,
  });

  final int points;
  final int? groupRank;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
