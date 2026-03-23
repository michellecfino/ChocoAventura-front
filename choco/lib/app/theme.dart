import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(
      color: AppColors.text,
    ),
  ),
);