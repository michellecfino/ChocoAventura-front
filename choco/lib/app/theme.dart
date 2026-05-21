import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.accentMuted,
    onSecondary: AppColors.text,
    surface: AppColors.surfaceElevated,
    onSurface: AppColors.text,
    error: AppColors.owe,
    outline: AppColors.text.withValues(alpha: 0.18),
  ),
  appBarTheme: AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.text,
    titleTextStyle: GoogleFonts.fredoka(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.creamLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.text.withValues(alpha: 0.85)),
    hintStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.text.withValues(alpha: 0.45)),
  ),
  textTheme: GoogleFonts.nunitoTextTheme().apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  ).copyWith(
    displayLarge: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.text),
    displayMedium: GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text),
    headlineMedium: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
    titleLarge: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text),
    titleMedium: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text),
    bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text),
    bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
    bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.text.withValues(alpha: 0.78)),
    labelLarge: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
  ),
);
