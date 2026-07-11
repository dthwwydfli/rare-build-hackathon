import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tactile_widgets.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      onTap: onTap,
      padding: padding,
      color: color,
      child: child,
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.lavender),
          if (message != null) ...[
            const SizedBox(height: 16),
            LowercaseText(message!),
          ],
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(child: LowercaseText(message)),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'confirm',
  String cancelLabel = 'cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: LowercaseText(title),
      content: LowercaseText(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: LowercaseText(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: LowercaseText(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: LowercaseText(message, style: const TextStyle(color: AppTheme.white))),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.lavender),
            const SizedBox(height: 16),
            LowercaseText(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LowercaseText(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.granolaDark.withValues(alpha: 0.7)),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.lavenderLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.granolaDark),
          const SizedBox(width: 6),
          LowercaseText(
            '$label $value',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  Color get _color {
    switch (rank) {
      case 1:
        return AppTheme.lavender;
      case 2:
        return AppTheme.granola;
      case 3:
        return AppTheme.lavenderLight;
      default:
        return AppTheme.granolaLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: rank <= 2 ? AppTheme.white : AppTheme.granolaDark,
        ),
      ),
    );
  }
}

class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final hot = streak >= 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: hot
            ? const LinearGradient(
                colors: [AppTheme.granola, AppTheme.lavender],
              )
            : null,
        color: hot ? null : AppTheme.lavenderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 18,
            color: hot ? AppTheme.white : AppTheme.lavenderDark,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hot ? AppTheme.white : AppTheme.granolaDark,
            ),
          ),
        ],
      ),
    );
  }
}

class PointsCard extends StatelessWidget {
  const PointsCard({
    super.key,
    required this.points,
    this.compact = false,
  });

  final int points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.white,
            AppTheme.lavenderLight.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lavenderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const LowercaseText('points', style: TextStyle(fontSize: 12)),
          Text(
            '$points',
            style: TextStyle(
              fontSize: compact ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.granola,
            ),
          ),
          LowercaseText(
            pointsTierLabel(points),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.lavenderDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PodiumRow extends StatelessWidget {
  const PodiumRow({super.key, required this.entries});

  final List<({String name, int points, int rank})> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final sorted = List.of(entries)..sort((a, b) => a.rank.compareTo(b.rank));
    final top3 = sorted.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _PodiumSlot(entry: top3[1], height: 72),
          if (top3.isNotEmpty) _PodiumSlot(entry: top3[0], height: 96),
          if (top3.length > 2) _PodiumSlot(entry: top3[2], height: 56),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({required this.entry, required this.height});

  final ({String name, int points, int rank}) entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RankBadge(rank: entry.rank),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '${entry.points}',
          style: TextStyle(fontSize: 11, color: AppTheme.granolaDark.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Container(
          width: 72,
          height: height,
          decoration: BoxDecoration(
            color: entry.rank == 1
                ? AppTheme.lavender
                : entry.rank == 2
                    ? AppTheme.granola
                    : AppTheme.lavenderLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.granola,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LowercaseText(
        pointsTierLabel(points),
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
