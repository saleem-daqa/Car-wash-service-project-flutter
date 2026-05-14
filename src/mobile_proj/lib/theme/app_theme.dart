import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF172554);
  static const Color teal = Color(0xFF0F9F6E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF101828);

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryBlue,
          secondary: teal,
          tertiary: amber,
          surface: surface,
          error: const Color(0xFFDC2626),
          onSurface: ink,
        );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: background,
      appBarTheme: _appBarTheme(colorScheme, surface),
      cardTheme: _cardTheme(surface),
      inputDecorationTheme: _inputDecorationTheme(colorScheme, surface),
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF7EA6FF),
          secondary: const Color(0xFF54D6A1),
          tertiary: const Color(0xFFFFC46B),
          surface: const Color(0xFF111827),
          error: const Color(0xFFFF7A7A),
        );

    return _base(colorScheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      appBarTheme: _appBarTheme(colorScheme, const Color(0xFF111827)),
      cardTheme: _cardTheme(const Color(0xFF111827)),
      inputDecorationTheme: _inputDecorationTheme(
        colorScheme,
        const Color(0xFF0F172A),
      ),
    );
  }

  static ThemeData _base(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
        titleSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
        bodyLarge: TextStyle(letterSpacing: 0, height: 1.35),
        bodyMedium: TextStyle(letterSpacing: 0, height: 1.35),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
      ),
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colorScheme, Color background) {
    return AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w800,
        fontSize: 20,
        letterSpacing: 0,
      ),
    );
  }

  static CardThemeData _cardTheme(Color color) {
    return CardThemeData(
      color: color,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    ColorScheme colorScheme,
    Color fill,
  ) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
    );
  }
}
