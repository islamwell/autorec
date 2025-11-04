import 'package:flutter/material.dart';

/// Application theme configuration with Material Design 3
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

  /// Dark theme for the voice keyword recorder app with Material Design 3
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B86FF), // Lighter, more vibrant blue for MD3
        onPrimary: Color(0xFF000C3E),
        primaryContainer: Color(0xFF1A237E),
        onPrimaryContainer: Color(0xFFDCE1FF),

        secondary: Color(0xFFB39DDB), // Lighter purple for MD3
        onSecondary: Color(0xFF2D1446),
        secondaryContainer: Color(0xFF4A148C),
        onSecondaryContainer: Color(0xFFE8DDFF),

        tertiary: Color(0xFFFFB74D), // Lighter orange for MD3
        onTertiary: Color(0xFF451F00),
        tertiaryContainer: Color(0xFFE65100),
        onTertiaryContainer: Color(0xFFFFDCC1),

        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),

        background: Color(0xFF1A1C1E),
        onBackground: Color(0xFFE2E2E6),

        surface: Color(0xFF1A1C1E),
        onSurface: Color(0xFFE2E2E6),
        surfaceVariant: Color(0xFF44464F),
        onSurfaceVariant: Color(0xFFC5C6D0),

        outline: Color(0xFF8F9099),
        outlineVariant: Color(0xFF44464F),

        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),

        inverseSurface: Color(0xFFE2E2E6),
        onInverseSurface: Color(0xFF2E3135),
        inversePrimary: Color(0xFF3D5AFE),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 6,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Light theme for the voice keyword recorder app with Material Design 3
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3D5AFE),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFDCE1FF),
        onPrimaryContainer: Color(0xFF000C3E),

        secondary: Color(0xFF6A1B9A),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFE8DDFF),
        onSecondaryContainer: Color(0xFF2D1446),

        tertiary: Color(0xFFFF6F00),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFFFDCC1),
        onTertiaryContainer: Color(0xFF451F00),

        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        background: Color(0xFFFDFBFF),
        onBackground: Color(0xFF1A1C1E),

        surface: Color(0xFFFDFBFF),
        onSurface: Color(0xFF1A1C1E),
        surfaceVariant: Color(0xFFE2E1EC),
        onSurfaceVariant: Color(0xFF44464F),

        outline: Color(0xFF75777F),
        outlineVariant: Color(0xFFC5C6D0),

        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),

        inverseSurface: Color(0xFF2F3033),
        onInverseSurface: Color(0xFFF1F0F4),
        inversePrimary: Color(0xFF6B86FF),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 6,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}