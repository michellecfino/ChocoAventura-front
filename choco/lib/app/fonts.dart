import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// **Fredoka** (títulos) + **Nunito** (cuerpo): misma línea que “Iniciar sesión” / AppBar — cálida y redondeada.
abstract final class AppFonts {
  static TextStyle display(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: AppColors.text, height: 1.15);

  static TextStyle title(double size, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: AppColors.text);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color, double? height}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.text,
        height: height ?? 1.35,
      );

  static TextStyle label(double size, {FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: AppColors.text);

  static TextStyle amount(double size, {FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: AppColors.text, letterSpacing: -0.2);
}
