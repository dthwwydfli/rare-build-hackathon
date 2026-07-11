import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return LowercaseText(
      'lavender',
      style: brandWordmark(size: size),
      textAlign: TextAlign.center,
    );
  }
}

class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.paperSurface, AppTheme.surface],
        ),
      ),
      child: CustomPaint(
        painter: _PaperTexturePainter(),
        child: child,
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.ornamentAccent.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Paper fiber speckles. Seeded so the sheet looks identical every build.
    final rng = math.Random(7);
    final fiberPaint = Paint()
      ..color = AppTheme.ornamentAccent.withValues(alpha: 0.05);
    final goldPaint = Paint()
      ..color = AppTheme.amberGold.withValues(alpha: 0.05);
    for (var i = 0; i < 120; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1, i % 3 == 0 ? goldPaint : fiberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws [path] as a running dash pattern. Shared by the stitch-styled
/// painters in this file and in craft_widgets.dart.
void drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dashLength,
  required double gapLength,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final next = math.min(distance + dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance += dashLength + gapLength;
    }
  }
}

class StitchedBorder extends StatelessWidget {
  const StitchedBorder({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(3),
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StitchedBorderPainter(borderRadius: borderRadius),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _StitchedBorderPainter extends CustomPainter {
  _StitchedBorderPainter({required this.borderRadius});

  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final outerPaint = Paint()
      ..color = AppTheme.lavender.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, outerPaint);

    final dashPaint = Paint()
      ..color = AppTheme.stitchBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()..addRRect(rrect.deflate(4));
    drawDashedPath(canvas, path, dashPaint, dashLength: 6, gapLength: 4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.ornamentAccent.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.ornamentAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.ornamentAccent.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TactileCard extends StatelessWidget {
  const TactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.useStitch = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final bool useStitch;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.stitchBorder.withValues(alpha: 0.6)),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.warmShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (useStitch) {
      return StitchedBorder(child: card);
    }
    return card;
  }
}
