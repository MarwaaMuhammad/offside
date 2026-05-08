import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Dark Mode ──────────────────────────────────────
  static const Color darkBg         = Color(0xFF121212);
  static const Color darkCard       = Color(0xFF1E1E1E);
  static const Color darkCardAlt    = Color(0xFF252525);
  static const Color darkPrimary    = Color(0xFF00C853); // Green
  static const Color darkSecondary  = Color(0xFF0288D1); // Blue
  static const Color darkAccent     = Color(0xFFFF6D00); // Orange
  static const Color darkError      = Color(0xFFEF5350);
  static const Color darkSuccess    = Color(0xFF4CAF50);
  static const Color darkTextPri    = Color(0xFFFFFFFF);
  static const Color darkTextSec    = Color(0xFFB0B0B0);
  static const Color darkDivider    = Color(0xFF2A2A2A);
  static const Color darkNavBar     = Color(0xFF181818);

  // ── Light Mode ─────────────────────────────────────
  static const Color lightBg        = Color(0xFFF5F7FA);
  static const Color lightCard      = Color(0xFFFFFFFF);
  static const Color lightPrimary   = Color(0xFF00A63E);
  static const Color lightSecondary = Color(0xFF1E88E5);
  static const Color lightAccent    = Color(0xFFFF6D00);
  static const Color lightError     = Color(0xFFEF5350);
  static const Color lightSuccess   = Color(0xFF4CAF50);
  static const Color lightTextPri   = Color(0xFF1C1C1C);
  static const Color lightTextSec   = Color(0xFF6B7280);
  static const Color lightDivider   = Color(0xFFE5E7EB);
}

class ThemeProvider {
  // Default to dark mode
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _updateSystemUI(themeMode.value == ThemeMode.dark);
  }

  static void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.darkNavBar,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: AppColors.lightBg,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );
  }

  // ── Light Theme ────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.lightPrimary,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      tertiary: AppColors.lightAccent,
      surface: AppColors.lightCard,
      error: AppColors.lightError,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPri,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.lightTextPri),
      headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.lightTextPri),
      titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.lightTextPri),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightTextPri),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.lightTextPri),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: AppColors.lightTextSec),
      labelLarge: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBg,
      foregroundColor: AppColors.lightTextPri,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.lightTextPri,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightDivider, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.lightTextSec, fontSize: 14),
    ),
    dividerColor: AppColors.lightDivider,
    iconTheme: const IconThemeData(color: AppColors.lightTextSec),
  );

  // ── Dark Theme ─────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary,
      tertiary: AppColors.darkAccent,
      surface: AppColors.darkCard,
      error: AppColors.darkError,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPri,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkTextPri),
      headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkTextPri),
      titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPri),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkTextPri),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.darkTextPri),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: AppColors.darkTextSec),
      labelLarge: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkTextPri,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: AppColors.darkTextPri,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(color: AppColors.darkTextSec, fontSize: 14),
    ),
    dividerColor: const Color(0xFF2A2A2A),
    iconTheme: const IconThemeData(color: AppColors.darkTextSec),
  );
}
