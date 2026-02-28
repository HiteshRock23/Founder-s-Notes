import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color backgroundWhite = Colors.white;
  static const Color cardGray = Color(0xFFF5F5F5);
  static const Color textGray = Colors.grey;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: backgroundWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.black),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textGray,
          fontSize: 12,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: textGray,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.0, color: primaryBlue),
        ),
      ),
    );
  }
}
