import 'package:flutter/material.dart';

import '../../domain/models/app_user.dart';

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
          const CircularProgressIndicator(color: AppTheme.lavenderDeep),
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
        color: AppTheme.dangerDeep.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dangerDeep.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.dangerDeep),
          const SizedBox(width: 8),
          Expanded(
            child: LowercaseText(
              message,
              style: const TextStyle(color: AppTheme.dangerDeep),
            ),
          ),
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
    SnackBar(
      content: LowercaseText(
        message,
        style: const TextStyle(color: AppTheme.paperSurface),
      ),
    ),
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
            const _BlankPaper(),
            const SizedBox(height: 12),
            const OrnamentalDivider(width: 90),
            const SizedBox(height: 12),
            LowercaseText(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LowercaseText(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.inkPlumSoft),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// A small blank sheet with a stitched border — the "nothing written here
/// yet" mark used by [EmptyState].
class _BlankPaper extends StatelessWidget {
  const _BlankPaper();

  @override
  Widget build(BuildContext context) {
    return StitchedBorder(
      borderRadius: 10,
      padding: const EdgeInsets.all(6),
      child: Container(
        width: 56,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.paperSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 22,
          color: AppTheme.inkPlumSoft,
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
          Icon(icon, size: 16, color: AppTheme.inkPlumSoft),
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
        return AppTheme.granola;
      case 2:
        return AppTheme.lavenderDeep;
      case 3:
        return AppTheme.lavenderDark;
      default:
        return AppTheme.inkPlumSoft;
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
        border: Border.all(color: AppTheme.paperSurface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$rank',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppTheme.white,
        ),
      ),
    );
  }
}

/// Streak marker. Renders growth (a sprout and days reclaimed), not fire —
/// heat/urgency metaphors are wrong for a recovery audience.
class StreakFlame extends StatelessWidget {
  const StreakFlame({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.granolaLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sageDeep.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.spa_outlined, size: 18, color: AppTheme.sageDeep),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.sageDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class PointsCard extends StatelessWidget {
  const PointsCard({super.key, required this.points, this.compact = false});

  final int points;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.granolaLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.granola.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const LowercaseText(
            'points',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: AppTheme.sageDeep,
            ),
          ),
          Text(
            '$points',
            style: TextStyle(
              fontSize: compact ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.sageDeep,
            ),
          ),
          LowercaseText(
            softTierLabel(points),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.inkPlumSoft,
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

    // A quilt of near-equal patches, not a podium — this leaderboard is
    // about walking together, not towering over each other.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length > 1) _PodiumSlot(entry: top3[1], height: 72),
          if (top3.isNotEmpty) _PodiumSlot(entry: top3[0], height: 80),
          if (top3.length > 2) _PodiumSlot(entry: top3[2], height: 68),
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
    return StitchedBorder(
      borderRadius: 14,
      padding: const EdgeInsets.all(6),
      child: Container(
        width: 92,
        height: height + 52,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.paperSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RankBadge(rank: entry.rank),
            const SizedBox(height: 6),
            Text(
              entry.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkPlum,
              ),
            ),
            Text(
              '${entry.points}',
              style: const TextStyle(fontSize: 11, color: AppTheme.inkPlumSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    // Mini ink-stamp look: paper fill, green ring, slight tilt.
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.paperSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.granola.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: LowercaseText(
          softTierLabel(points),
          style: const TextStyle(
            color: AppTheme.sageDeep,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.user, this.radius = 22});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName.trim() ?? '';
    final color = Color(user?.avatarColor ?? 0xFF6E5A8E);
    final avatarAsset = user?.avatarAsset;

    if (avatarAsset != null && avatarAsset.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color.withValues(alpha: 0.16),
        backgroundImage: AssetImage(avatarAsset),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 0.58),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _initials(name),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: radius * 0.62,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class CommunityAvatarStack extends StatelessWidget {
  const CommunityAvatarStack({
    super.key,
    required this.users,
    this.maxVisible = 4,
    this.radius = 18,
  });

  final List<AppUser> users;
  final int maxVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final visible = users.take(maxVisible).toList();
    final extra = users.length - visible.length;
    return SizedBox(
      height: radius * 2,
      width: (visible.length + (extra > 0 ? 1 : 0)) * radius * 1.35 + radius,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * radius * 1.35,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.paperSurface, width: 2),
                ),
                child: CommunityAvatar(user: visible[i], radius: radius),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * radius * 1.35,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: AppTheme.lavenderDeep,
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    color: AppTheme.paperSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
