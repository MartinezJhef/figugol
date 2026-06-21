import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const primaryBrand = Color(0xFF4ADE80);    // Vibrant Neon Green (from images)
  static const secondaryBrand = Color(0xFFE3242B);  // Red
  static const accentBrand = Color(0xFF22C55E);     // Darker Neon Green
  static const lightText = Color(0xFFF9FAFB);       // Light text for dark mode
  static const borderLine = Color(0xFF2E3D34);      // Dark green-grey border
  static const bgDark = Color(0xFF0A0F0D);          // Very dark greenish black (Image background)
  static const cardDark = Color(0xFF161F1A);        // Slightly lighter card background

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: primaryBrand,
      primary: primaryBrand,
      secondary: secondaryBrand,
      tertiary: accentBrand,
      surface: bgDark,
      onSurface: lightText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Modern rounded corners (shapes from image)
          side: const BorderSide(color: borderLine),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardDark,
        contentTextStyle: const TextStyle(
          color: lightText,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6), // Light grey/white like the "See More" button
          foregroundColor: const Color(0xFF111827), // Dark text
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded button
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          foregroundColor: const Color(0xFF111827),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightText,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: borderLine, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardDark,
        indicatorColor: primaryBrand.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? accentBrand : lightText,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accentBrand : lightText,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), // Rounded inputs
          borderSide: const BorderSide(color: borderLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 1.6),
        ),
      ),
    );
  }
}
