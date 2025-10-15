import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  // Color constants for demo screens
  static const Color primaryDark = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3F51B5);
  static const Color secondaryDark = Color(0xFF4A148C);
  static const Color secondaryLight = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFE65100);
  static const Color accentOrangeLight = Color(0xFFFF9800);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFFFAFAFA);

  // Gradient constants
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surfaceDark, Color(0xFF121212)],
  );
  /// Dark theme for the voice keyword recorder app
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1A237E),
        secondary: Color(0xFF4A148C),
        tertiary: Color(0xFFE65100),
        surface: Color(0xFF1E1E1E),
        surfaceVariant: Color(0xFF121212),
        error: Color(0xFFC62828),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.white70,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }

  /// Light theme for the voice keyword recorder app
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A237E),
        secondary: Color(0xFF4A148C),
        tertiary: Color(0xFFE65100),
        surface: Color(0xFFFAFAFA),
        surfaceVariant: Color(0xFFF5F5F5),
        error: Color(0xFFC62828),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.black54,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }
}