import 'package:flutter/material.dart';

/// Paleta ChocoAventura + derivados para más profundidad (menos “plano”).
class AppColors {
  static const Color background = Color(0xFFF9E0BB);
  static const Color primary = Color(0xFF697235);
  static const Color text = Color(0xFF794634);
  static const Color accent = Color(0xFFFFA840);

  static const Color primaryDark = Color(0xFF4D5328);
  static const Color creamLight = Color(0xFFFFF6E8);
  static const Color surfaceElevated = Color(0xFFFFFBF5);

  /// Fondo detrás del “teléfono” en web/desktop ancho.
  static const Color shellOutside = Color(0xFFF0DEC6);

  static const Color surface = Color(0xFFFFF9F0);
  static const Color surfaceMuted = Color(0xFFFFF3E4);

  static Color accentSoft = const Color(0xFFFFA840).withValues(alpha: 0.2);
  static Color accentMuted = const Color(0xFFE8954A);

  static Color outlineSoft = const Color(0xFF794634).withValues(alpha: 0.12);

  static Color shadowWarm = const Color(0xFF5C3D2E).withValues(alpha: 0.08);

  /// Semántica dinero
  static const Color owe = Color(0xFFB85C3D);
  static const Color owed = Color(0xFF5A6E2E);
}
