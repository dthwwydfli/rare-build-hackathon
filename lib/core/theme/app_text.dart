import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/enums.dart';
import 'app_theme.dart';

/// Lowercase display copy for static UI strings.
String lc(String s) => s.toLowerCase();

TextStyle brandWordmark({double size = 28}) => GoogleFonts.poppins(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: AppTheme.lavenderDeep,
      letterSpacing: -0.5,
    );

class LowercaseText extends StatelessWidget {
  const LowercaseText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      lc(data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

String pointsTierLabel(int points) {
  if (points >= 1200) return 'master';
  if (points >= 1100) return 'advanced';
  if (points >= 1000) return 'intermediate';
  return 'beginner';
}

/// UI-layer tier names with growth framing. The point bands mirror
/// [pointsTierLabel], which stays untouched as part of the shared contract.
String softTierLabel(int points) {
  if (points >= 1200) return 'gardener';
  if (points >= 1100) return 'bloom';
  if (points >= 1000) return 'sprout';
  return 'seedling';
}

/// Softer user-facing wording for breach signals. Enum labels in
/// lib/domain/models/enums.dart are shared with detection code and stay as-is.
String softSignal(BreachSignalType type) {
  switch (type) {
    case BreachSignalType.location:
      return 'near a trigger spot';
    case BreachSignalType.app:
      return 'opened a flagged app';
    case BreachSignalType.url:
      return 'visited a flagged site';
    case BreachSignalType.payment:
      return 'a flagged payment';
    case BreachSignalType.manual:
      return 'checked in';
  }
}
