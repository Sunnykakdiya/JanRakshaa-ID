import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Rich Neo-Medical Palette
  static const Color primaryColor = Color(0xFF0066CC);    // Royal Clinical Blue
  static const Color secondaryColor = Color(0xFF00B4D8);  // Bio-Cyan
  static const Color darkNavy = Color(0xFF0A192F);        // Deep Command Navy
  static const Color accentColor = Color(0xFFFF5A36);     // Emergency Pulse Orange
  static const Color successColor = Color(0xFF10B981);    // Vital Emerald
  static const Color errorColor = Color(0xFFEF4444);      // Crimson Alert
  static const Color backgroundColor = Color(0xFFF0F4F9); // Soft Clinical Mesh Grey
  static const Color cardColor = Colors.white;

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  static const LinearGradient idCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A192F),
      Color(0xFF004E92),
      Color(0xFF0077B6),
    ],
  );

  static const LinearGradient sosGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}