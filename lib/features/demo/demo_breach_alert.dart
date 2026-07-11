import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../screening/screening_rescreen_prompt.dart';

/// Demo notification-style alert for a Paddy Power breach.
Future<void> showDemoPaddyPowerAlert(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss alert',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, __) => const _DemoPaddyPowerAlertBody(),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.15),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _DemoPaddyPowerAlertBody extends StatelessWidget {
  const _DemoPaddyPowerAlertBody();

  void _dismiss(BuildContext context) => Navigator.of(context).pop();

  void _getSupport(BuildContext context) {
    Navigator.of(context).pop();
    showHelplineSupportSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.paperSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.granola.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.warmShadow,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.granola.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppTheme.granola,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LowercaseText(
                                'paddy power',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.inkPlum,
                                  height: 1.25,
                                ),
                              ),
                              SizedBox(height: 6),
                              LowercaseText(
                                'your support circle has been notified',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.inkPlumSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _dismiss(context),
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.inkPlumSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const LowercaseText(
                      'you committed to avoid betting venues. want to turn around or reach out?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkPlumSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _dismiss(context),
                            child: const LowercaseText('i\'m turning around'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _getSupport(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.granola,
                            ),
                            child: const LowercaseText('get support'),
                          ),
                        ),
                      ],
                    ),
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
