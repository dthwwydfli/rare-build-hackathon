import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'tactile_widgets.dart';

/// Craft components for lavender's tactile design language: rubber stamps,
/// signed paper contracts, ticket stubs, wax seals, running-stitch progress,
/// and fabric patches. All shapes are deterministic — rotations come from
/// seeds, never from per-build randomness.

double _seededTilt(String seed, {double maxDegrees = 5}) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final fraction = (hash % 1000) / 1000; // 0..1
  return (fraction - 0.5) * 2 * maxDegrees * math.pi / 180;
}

// ---------------------------------------------------------------------------
// StampBadge
// ---------------------------------------------------------------------------

class StampBadge extends StatelessWidget {
  const StampBadge({
    super.key,
    required this.label,
    this.icon,
    this.size = 56,
    this.color = AppTheme.granola,
    this.seed,
  });

  /// Tier stamp derived from points, in growth language.
  StampBadge.tier(int points, {super.key, this.size = 56})
      : label = softTierLabel(points),
        icon = Icons.spa_outlined,
        color = AppTheme.granola,
        seed = softTierLabel(points);

  const StampBadge.active({super.key, this.size = 56})
      : label = 'active',
        icon = Icons.check,
        color = AppTheme.granola,
        seed = 'active';

  const StampBadge.milestone(this.label, {super.key, this.size = 56})
      : icon = Icons.star_outline,
        color = AppTheme.granola,
        seed = null;

  final String label;
  final IconData? icon;
  final double size;
  final Color color;
  final String? seed;

  @override
  Widget build(BuildContext context) {
    final ink = color.withValues(alpha: 0.85);
    return Transform.rotate(
      angle: _seededTilt(seed ?? label),
      child: CustomPaint(
        painter: _StampRingPainter(ink),
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, size: size * 0.34, color: ink),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LowercaseText(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: ink,
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StampRingPainter extends CustomPainter {
  _StampRingPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final outer = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, outer);

    final inner = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final innerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 5));
    drawDashedPath(canvas, innerPath, inner, dashLength: 4, gapLength: 3);
  }

  @override
  bool shouldRepaint(covariant _StampRingPainter oldDelegate) =>
      oldDelegate.ink != ink;
}

// ---------------------------------------------------------------------------
// ContractCard
// ---------------------------------------------------------------------------

class ContractCard extends StatelessWidget {
  const ContractCard({
    super.key,
    required this.child,
    this.title,
    this.signedBy,
    this.stamp,
    this.onTap,
    this.faded = false,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 16),
  });

  final Widget child;
  final String? title;

  /// Renders a dashed signature line footer: "signed, {name}".
  final String? signedBy;

  /// Widget overlapping the top-right corner, usually a [StampBadge].
  final Widget? stamp;
  final VoidCallback? onTap;

  /// Paused/inactive contracts fade rather than disappear.
  final bool faded;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheet = Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipPath(
        clipper: _DeckleEdgeClipper(),
        child: Material(
          color: AppTheme.paperSurface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Padding(
                      // Keeps the title clear of an overlapping corner stamp.
                      padding: EdgeInsets.only(right: stamp != null ? 56 : 0),
                      child: LowercaseText(title!,
                          style: theme.textTheme.titleLarge),
                    ),
                    const SizedBox(height: 6),
                    Container(height: 1, color: AppTheme.stitchBorder),
                    const SizedBox(height: 12),
                  ],
                  child,
                  if (signedBy != null) ...[
                    const SizedBox(height: 14),
                    const _SignatureLine(),
                    const SizedBox(height: 4),
                    LowercaseText(
                      'signed, $signedBy',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppTheme.inkPlumSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final body = Stack(
      clipBehavior: Clip.none,
      children: [
        sheet,
        if (stamp != null) Positioned(top: -6, right: 10, child: stamp!),
      ],
    );

    return faded ? Opacity(opacity: 0.6, child: body) : body;
  }
}

class _SignatureLine extends StatelessWidget {
  const _SignatureLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(AppTheme.inkPlumSoft)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter(this.color, {this.vertical = false});

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(vertical ? 0 : size.width, vertical ? size.height : 0);
    drawDashedPath(canvas, path, paint, dashLength: 5, gapLength: 4);
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.vertical != vertical;
}

class _DeckleEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const radius = 14.0;
    final path = Path()..moveTo(0, radius);

    // Gently irregular scallops along the top edge — deterministic pattern.
    const heights = [2.5, 1.0, 3.0, 1.5, 2.0, 3.5, 1.0, 2.5];
    final segment = size.width / (heights.length * 2);
    path.lineTo(0, 4);
    var x = 0.0;
    for (var i = 0; i < heights.length * 2; i++) {
      final dip = heights[i % heights.length];
      x += segment;
      path.quadraticBezierTo(
        x - segment / 2,
        i.isEven ? dip : -dip / 2 + 3,
        math.min(x, size.width),
        2 + dip / 2,
      );
    }
    path.lineTo(size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
        size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// TicketStub
// ---------------------------------------------------------------------------

class TicketStub extends StatelessWidget {
  const TicketStub({
    super.key,
    this.code,
    this.onCopy,
    this.onShare,
  });

  /// Invite code. When null, renders a decorative blank stub.
  final String? code;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TicketClipper(),
      child: Container(
        color: AppTheme.granolaLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LowercaseText(
                        'invite code',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: AppTheme.sageDeep,
                        ),
                      ),
                      SizedBox(height: 2),
                      LowercaseText(
                        'tear & share',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.inkPlumSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 1,
                child: CustomPaint(
                  painter:
                      _DashedLinePainter(AppTheme.sageDeep, vertical: true),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code ?? '· · · · · ·',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: AppTheme.inkPlum,
                          ),
                        ),
                      ),
                      if (code != null) ...[
                        IconButton(
                          onPressed: onCopy ??
                              () {
                                Clipboard.setData(ClipboardData(text: code!));
                              },
                          icon: const Icon(Icons.copy, size: 20),
                          color: AppTheme.sageDeep,
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                          tooltip: 'copy',
                        ),
                        if (onShare != null)
                          IconButton(
                            onPressed: onShare,
                            icon: const Icon(Icons.ios_share, size: 20),
                            color: AppTheme.sageDeep,
                            constraints: const BoxConstraints(
                                minWidth: 44, minHeight: 44),
                            tooltip: 'share',
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 8.0;
    const radius = 12.0;
    final rect = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(radius),
      ));
    final notches = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(0, size.height / 2), radius: notch))
      ..addOval(Rect.fromCircle(
          center: Offset(size.width, size.height / 2), radius: notch));
    return Path.combine(PathOperation.difference, rect, notches);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// WaxSealCheck
// ---------------------------------------------------------------------------

class WaxSealCheck extends StatelessWidget {
  const WaxSealCheck({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaxSealPainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.favorite,
            size: size * 0.45,
            color: AppTheme.white,
          ),
        ),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2;

    final path = Path();
    const lobes = 12;
    for (var i = 0; i <= 64; i++) {
      final angle = i / 64 * 2 * math.pi;
      final radius = base * (0.92 + 0.08 * math.sin(angle * lobes));
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [AppTheme.lavenderDark, AppTheme.lavenderDeep],
      ).createShader(Rect.fromCircle(center: center, radius: base));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// StitchProgress
// ---------------------------------------------------------------------------

class StitchProgress extends StatelessWidget {
  const StitchProgress({super.key, required double this.value})
      : count = null,
        index = null;

  /// Stitched page-indicator dots (e.g. onboarding).
  const StitchProgress.dots({
    super.key,
    required int this.count,
    required int this.index,
  }) : value = null;

  final double? value;
  final int? count;
  final int? index;

  @override
  Widget build(BuildContext context) {
    if (count != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count!; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index
                    ? AppTheme.sageDeep
                    : AppTheme.stitchBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );
    }
    return SizedBox(
      height: 10,
      width: double.infinity,
      child: CustomPaint(
        painter: _StitchProgressPainter(value!.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _StitchProgressPainter extends CustomPainter {
  _StitchProgressPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;

    final remaining = Paint()
      ..color = AppTheme.stitchBorder.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    drawDashedPath(
      canvas,
      Path()
        ..moveTo(0, y)
        ..lineTo(size.width, y),
      remaining,
      dashLength: 6,
      gapLength: 4,
    );

    if (value > 0) {
      final done = Paint()
        ..color = AppTheme.sageDeep
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final doneWidth = size.width * value;
      drawDashedPath(
        canvas,
        Path()
          ..moveTo(0, y)
          ..lineTo(doneWidth, y),
        done,
        dashLength: 6,
        gapLength: 4,
      );
      // Thread knot at the end of the completed stitch.
      canvas.drawCircle(
          Offset(doneWidth, y), 3, Paint()..color = AppTheme.sageDeep);
    }
  }

  @override
  bool shouldRepaint(covariant _StitchProgressPainter oldDelegate) =>
      oldDelegate.value != value;
}

// ---------------------------------------------------------------------------
// PatchChip
// ---------------------------------------------------------------------------

class PatchChip extends StatelessWidget {
  const PatchChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.tilted = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  /// Fixed slight rotation for a hand-placed sticker feel.
  final bool tilted;

  @override
  Widget build(BuildContext context) {
    final chip = CustomPaint(
      painter: _PatchBorderPainter(selected: selected),
      child: Material(
        color: selected ? AppTheme.lavenderLight : AppTheme.paperSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 16,
                      color: selected
                          ? AppTheme.lavenderDeep
                          : AppTheme.inkPlumSoft),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: LowercaseText(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppTheme.lavenderDeep : AppTheme.inkPlum,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return tilted
        ? Transform.rotate(angle: _seededTilt(label, maxDegrees: 2), child: chip)
        : chip;
  }
}

class _PatchBorderPainter extends CustomPainter {
  _PatchBorderPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = selected ? AppTheme.lavenderDeep : AppTheme.stitchBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(10),
      ));
    drawDashedPath(canvas, path, paint, dashLength: 5, gapLength: 3);
  }

  @override
  bool shouldRepaint(covariant _PatchBorderPainter oldDelegate) =>
      oldDelegate.selected != selected;
}

// ---------------------------------------------------------------------------
// DaysReclaimedCard
// ---------------------------------------------------------------------------

class DaysReclaimedCard extends StatelessWidget {
  const DaysReclaimedCard({
    super.key,
    required this.days,
    this.bestDays,
    this.dense = false,
  });

  final int days;

  /// Best streak — always shown when provided; a hard moment never erases it.
  final int? bestDays;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TactileCard(
      useStitch: !dense,
      padding: EdgeInsets.all(dense ? 14 : 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$days',
                      style: TextStyle(
                        fontSize: dense ? 32 : 40,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkPlum,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    LowercaseText(
                      'days reclaimed',
                      style: TextStyle(
                        fontSize: dense ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkPlumSoft,
                      ),
                    ),
                  ],
                ),
                if (bestDays != null) ...[
                  const SizedBox(height: 4),
                  LowercaseText(
                    'best: $bestDays days and yours forever',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.inkPlumSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.spa_outlined,
            size: dense ? 28 : 36,
            color: AppTheme.sageDeep,
          ),
        ],
      ),
    );
  }
}
