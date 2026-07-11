import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand — lavender
  static const Color lavender = Color(0xFFB8A9C9);
  static const Color lavenderDark = Color(0xFF9B8AB5);
  static const Color lavenderLight = Color(0xFFE8E0F0);

  // Gamification — granola
  static const Color granola = Color(0xFF8B9A6B);
  static const Color granolaDark = Color(0xFF6B7A52);
  static const Color granolaLight = Color(0xFFC5D4A0);

  // Neutrals & tactile
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F4F0);
  static const Color paperSurface = Color(0xFFFFFCF8);
  static const Color stitchBorder = Color(0xFFD4C8E0);
  static const Color warmShadow = Color(0x339B8AB5);
  static const Color ornamentAccent = Color(0xFFC9BBDA);
  static const Color danger = Color(0xFFC45C5C);

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
        tertiary: lavenderDark,
        surface: surface,
        onSurface: granolaDark,
        error: danger,
        primaryContainer: lavenderLight,
        secondaryContainer: granolaLight,
      ),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: granolaDark,
      displayColor: granolaDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lavender,
        foregroundColor: white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paperSurface,
        indicatorColor: lavenderLight,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.poppins(fontSize: 12, color: granolaDark),
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
        labelStyle: GoogleFonts.poppins(color: granolaDark),
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
          borderSide: const BorderSide(color: lavender, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lavender,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          elevation: 2,
          shadowColor: warmShadow,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lavenderDark,
          side: const BorderSide(color: lavender),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lavenderDark,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lavender,
        foregroundColor: white,
        elevation: 3,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lavenderLight,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: granolaDark),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lavenderDark,
        contentTextStyle: GoogleFonts.poppins(color: white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
