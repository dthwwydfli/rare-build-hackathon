import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand — lavender
  static const Color lavender = Color(0xFFB8A9C9);
  static const Color lavenderDark = Color(0xFF9B8AB5);
  static const Color lavenderLight = Color(0xFFE8E0F0);

  // Ink — text & high-contrast surfaces
  static const Color inkPlum = Color(0xFF3B2E4A); // primary text, ~12:1 on paper
  static const Color inkPlumSoft = Color(0xFF5F5170); // secondary text, ~7:1
  static const Color lavenderDeep = Color(0xFF6E5A8E); // interactive text, ~5.9:1

  // Gamification — granola (decorative only; text uses sageDeep)
  static const Color granola = Color(0xFF8B9A6B);
  static const Color granolaDark = Color(0xFF6B7A52);
  static const Color granolaLight = Color(0xFFC5D4A0);
  static const Color sageDeep = Color(0xFF55643B); // growth text, ~7:1

  // Neutrals & tactile
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F1E8);
  static const Color paperSurface = Color(0xFFFFFBF2);
  static const Color stitchBorder = Color(0xFFD4C8E0);
  static const Color warmShadow = Color(0x339B8AB5);
  static const Color ornamentAccent = Color(0xFFC9BBDA);
  static const Color danger = Color(0xFFC45C5C);
  static const Color dangerDeep = Color(0xFFA34848); // error text, ~5.5:1

  // Legacy aliases
  static const Color primary = lavender;
  static const Color secondary = granolaLight;
  static const Color accent = lavenderLight;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lavender,
        primary: lavender,
        onPrimary: white,
        secondary: granola,
        onSecondary: white,
        tertiary: granola,
        surface: surface,
        onSurface: inkPlum,
        error: dangerDeep,
        primaryContainer: lavenderLight,
        secondaryContainer: granolaLight,
      ),
    );

    final poppins = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: inkPlum,
      displayColor: inkPlum,
    );

    final textTheme = poppins.copyWith(
      displaySmall: poppins.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineLarge: poppins.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: poppins.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: poppins.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: poppins.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: poppins.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      labelLarge: poppins.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: poppins.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: inkPlum,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: inkPlum,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paperSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: lavenderLight,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: inkPlum,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? inkPlum
                : inkPlumSoft,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: paperSurface,
        elevation: 0,
        shadowColor: warmShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: stitchBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paperSurface,
        labelStyle: GoogleFonts.poppins(color: inkPlumSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stitchBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stitchBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lavenderDeep, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkPlum,
          foregroundColor: paperSurface,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          elevation: 2,
          shadowColor: warmShadow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lavenderDeep,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: lavenderDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lavenderDeep,
          minimumSize: const Size(48, 44),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: sageDeep,
        foregroundColor: white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paperSurface,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: inkPlum),
        side: const BorderSide(color: stitchBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkPlum,
        contentTextStyle: GoogleFonts.poppins(color: paperSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
