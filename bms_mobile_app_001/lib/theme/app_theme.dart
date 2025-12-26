import 'package:flutter/material.dart';

class AppTheme {
  static const Color unicefBlue = Color(0xFF1CABE2);
  static const Color darkBlue = Color(0xFF0077B6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // COLOR SCHEME
      colorScheme: ColorScheme.fromSeed(
        seedColor: unicefBlue,
        primary: unicefBlue,
        secondary: darkBlue,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: const Color(0xFFF5F7FA),

      // APP BAR
      appBarTheme: const AppBarTheme(
        backgroundColor: unicefBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),

      // INPUT FIELDS
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),

      // BUTTONS
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: unicefBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ✔ FIXED: CARD THEME FOR FLUTTER 3.24+
      cardTheme: const CardThemeData(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
