import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Motion language for lavender.
///
/// Hard rules for this app's recovery audience — motion must never echo
/// gambling reward loops:
/// - no repeating/infinite animations, pulses, or shimmer
/// - no confetti or particle bursts
/// - no count-up number rollers
/// - no randomized timing or delays
/// Every animation runs exactly once, lasts under 500ms, and settles calmly.
/// All helpers become no-ops when the platform requests reduced motion.
class AppMotion {
  AppMotion._();

  static const Duration enter = Duration(milliseconds: 320);
  static const Duration stagger = Duration(milliseconds: 60);
  static const Curve settle = Curves.easeOutBack;
}

extension CraftEntrance on Widget {
  /// One-shot "pressed onto the page" entrance for stamps and seals.
  Widget stampIn(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.enter)
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1, 1),
          duration: AppMotion.enter,
          curve: AppMotion.settle,
        )
        .rotate(begin: 0.02, end: 0, duration: AppMotion.enter);
  }

  /// One-shot soft grow-in for acknowledgement seals.
  Widget sealIn(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return animate()
        .fadeIn(duration: AppMotion.enter)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: AppMotion.enter,
          curve: AppMotion.settle,
        );
  }
}

extension CraftStagger on List<Widget> {
  /// Gentle staggered entrance for list content. Delay is capped after the
  /// eighth item so long lists don't feel slow.
  List<Widget> staggered(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return this;
    return [
      for (var i = 0; i < length; i++)
        this[i]
            .animate(delay: AppMotion.stagger * (i < 8 ? i : 8))
            .fadeIn(duration: AppMotion.enter)
            .slideY(
              begin: 0.05,
              end: 0,
              duration: AppMotion.enter,
              curve: Curves.easeOut,
            ),
    ];
  }
}
