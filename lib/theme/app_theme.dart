import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Colors
  static const Color primaryBlue = Color(0xFF1E66F5);
  static const Color darkBlue = Color(0xFF0B3BAA);
  static const Color background = Color(0xFFF7FAFF);

  // 🌞 Light Theme
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
