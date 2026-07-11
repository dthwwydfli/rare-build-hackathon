import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/commitment_ui.dart';
import '../../../core/widgets/tactile_widgets.dart';
import '../../../domain/models/enums.dart';

class CommitmentTypeTile extends StatelessWidget {
  const CommitmentTypeTile({
    super.key,
    required this.type,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  final CommitmentType type;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = '${type.label} goal, ${type.description}';

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: selected,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: CustomPaint(
          painter: _TypeTileBorderPainter(selected: selected),
          child: Material(
            color: selected ? AppTheme.lavenderLight : AppTheme.paperSurface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      commitmentIcon(type),
                      size: 22,
                      color: selected
                          ? AppTheme.lavenderDeep
                          : AppTheme.inkPlumSoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LowercaseText(
                            type.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppTheme.lavenderDeep
                                  : AppTheme.inkPlum,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LowercaseText(
                            type.description,
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: AppTheme.inkPlumSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: AppTheme.sageDeep,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeTileBorderPainter extends CustomPainter {
  _TypeTileBorderPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = selected ? AppTheme.lavenderDeep : AppTheme.stitchBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.5 : 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        const Radius.circular(10),
      ));
    drawDashedPath(canvas, path, paint, dashLength: 5, gapLength: 3);
  }

  @override
  bool shouldRepaint(covariant _TypeTileBorderPainter oldDelegate) =>
      oldDelegate.selected != selected;
}
