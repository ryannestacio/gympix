import 'package:flutter/material.dart';

import 'app_theme_extensions.dart';

/// Tokens de layout do design system.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // --- Light theme (Material 3)
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Color(0xFF4F6BED),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8ECFF),
      onPrimaryContainer: Color(0xFF0F1D5C),
      secondary: Color(0xFF6B7280),
      onSecondary: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1D2E),
      onSurfaceVariant: Color(0xFF6B7280),
      outline: Color(0xFFE5E7EB),
      error: Color(0xFFEF4444),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const [AppThemeExtensions.light],
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF6F7FB),
        foregroundColor: Color(0xFF1A1D2E),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFF4F6BED), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        showDragHandle: true,
      ),
      textTheme: _textTheme(scheme.onSurface, scheme.onSurfaceVariant),
    );
  }

  // --- Dark theme (Linear / Vercel / Stripe inspired)
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF6C8CFF),
      onPrimary: Color(0xFF0F1115),
      primaryContainer: Color(0xFF2A3255),
      onPrimaryContainer: Color(0xFFDCE0FF),
      secondary: Color(0xFF8F9BB3),
      onSecondary: Color(0xFF1A1D24),
      surface: Color(0xFF1A1D24),
      onSurface: Color(0xFFF0F1F5),
      onSurfaceVariant: Color(0xFF8F9BB3),
      outline: Color(0xFF2D3139),
      surfaceContainerHighest: Color(0xFF252830),
      error: Color(0xFFFF5A5A),
      onError: Color(0xFF0F1115),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: const [AppThemeExtensions.dark],
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1115),
        foregroundColor: Color(0xFFF0F1F5),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFF2D3139)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFF6C8CFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        showDragHandle: true,
      ),
      textTheme: _textTheme(scheme.onSurface, scheme.onSurfaceVariant),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface),
      bodySmall: TextStyle(fontSize: 12, color: onSurfaceVariant),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
