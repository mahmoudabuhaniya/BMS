import 'package:flutter/material.dart';

class AppTheme {
  static const Color unicefBlue = Color(0xFF1CABE2);

  static ThemeData lightTheme = ThemeData(
    primaryColor: unicefBlue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: unicefBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
