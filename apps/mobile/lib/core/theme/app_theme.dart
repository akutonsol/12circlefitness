import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFF9F67FF);
  static const Color purpleDark = Color(0xFF5B21B6);
  static const Color charcoal = Color(0xFF374151);
  static const Color charcoalLight = Color(0xFF6B7280);
  // Navy-based dark palette (matches the home screen — no pure black).
  static const Color bgDark = Color(0xFF0B1326);
  static const Color bgDarkSecondary = Color(0xFF131B2E);
  static const Color bgDarkTertiary = Color(0xFF1B2238);
  static const Color surfaceDark = Color(0xFF182236);
  static const Color surfaceDarkElevated = Color(0xFF222A3D);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF38BDF8);
}

class AppStyles {
  static const TextStyle dashboardTitle = TextStyle(
    color: AppColors.white,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle sectionLabel = TextStyle(
    color: AppColors.textTertiary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );

  static const TextStyle metricValue = TextStyle(
    color: AppColors.white,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static BoxDecoration premiumCardDecoration = BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: AppColors.surfaceDarkElevated, width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 10)),
    ],
  );

  static BoxDecoration premiumPurpleCard = BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.purple, AppColors.purpleDark],
    ),
    boxShadow: const [
      BoxShadow(color: AppColors.purple, blurRadius: 30, spreadRadius: -10, offset: Offset(0, 12)),
    ],
  );

  static const List<BoxShadow> purpleGlow = [
    BoxShadow(color: AppColors.purple, blurRadius: 25, spreadRadius: -8, offset: Offset(0, 8)),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.purpleLight,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
          bodySmall: TextStyle(color: AppColors.textTertiary),
          labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.surfaceDarkElevated),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        thumbVisibility: WidgetStateProperty.all(true),
        interactive: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceDarkElevated)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.purple,
        secondary: AppColors.purpleLight,
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSurface: AppColors.black,
      ),
      scaffoldBackgroundColor: AppColors.white,
      textTheme: GoogleFonts.interTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
