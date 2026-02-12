import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111217), // Grafana Dark Background
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3274D9), // Grafana Blue
        secondary: Color(0xFF5794F2), // Lighter Blue
        surface: Color(0xFF181B1F), // Panel Background
        error: Color(0xFFE02F44), // Red
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFCCCCDC), // Text Color
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: const Color(0xFFCCCCDC),
        displayColor: const Color(0xFFCCCCDC),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111217),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF7F8FA),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFFCCCCDC)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF202226),
        thickness: 1,
      ),
      /*
      cardTheme: CardTheme(
        color: const Color(0xFF181B1F),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2), // Sharper corners like Grafana
          side: const BorderSide(color: Color(0xFF202226)), // Subtle border
        ),
      ),
      */
    );
  }
}
