import 'package:flutter/material.dart';

/// LED stadium / broadcast jumbotron look — dark green bg, glowing
/// LED-style score, amber accents. Kept as constants so every screen
/// pulls from the same palette.
class AppColors {
  static const bg = Color(0xFF0E1512);
  static const panel = Color(0xFF152019);
  static const panel2 = Color(0xFF1B2A20);
  static const line = Color(0xFF2A3B2E);
  static const accent = Color(0xFF3FAE5C); // LED green
  static const accentGlow = Color(0xFF6BFF9A);
  static const amber = Color(0xFFFFB703);
  static const text = Color(0xFFEEF2EE);
  static const muted = Color(0xFF8FA399);
  static const red = Color(0xFFE2504A);
  static const blue = Color(0xFF378ADD);
}

class AppTextStyles {
  static const ledScore = TextStyle(
    color: AppColors.accentGlow,
    fontSize: 46,
    fontWeight: FontWeight.w700,
    fontFamily: 'monospace',
    letterSpacing: 1,
    shadows: [
      Shadow(color: AppColors.accent, blurRadius: 18),
      Shadow(color: AppColors.accent, blurRadius: 6),
    ],
  );

  static const digital = TextStyle(
    color: AppColors.muted,
    fontSize: 14,
    fontFamily: 'monospace',
    letterSpacing: 0.5,
  );

  static const cardTitle = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const body = TextStyle(color: AppColors.text, fontSize: 15);
  static const small = TextStyle(color: AppColors.muted, fontSize: 12);
}

ThemeData buildAppTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bg,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.amber,
      surface: AppColors.panel,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}