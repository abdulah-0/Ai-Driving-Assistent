import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0D10);
  static const Color surfaceCard = Color(0xFF151820);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color electricGreen = Color(0xFF00E676);
  static const Color warningAmber = Color(0xFFFFAB00);
  static const Color dangerRed = Color(0xFFFF1744);
  static const Color frostedBorder = Color(0x1AFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static ThemeData get cyberNeonTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: neonCyan,
        secondary: electricGreen,
        surface: surfaceCard,
        error: dangerRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.0,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: textSecondary,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.8,
        ),
        labelLarge: GoogleFonts.orbitron(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: neonCyan,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceCard.withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: frostedBorder, width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: neonCyan),
    );
  }
}
