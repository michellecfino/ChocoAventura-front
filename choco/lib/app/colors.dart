import 'package:flutter/material.dart';

/// Paleta ChocoAventura — cálida, moderna, menos verde pesado.
///
/// Verde: protagonismo moderado (no dominante).
/// Crema/arena: fondos limpios y aireados.
/// Marrón cacao: tipografía y acentos con carácter.
class AppColors {
  // ── Fondos ────────────────────────────────────────────────────────────────
  /// Fondo principal de la app — arena suave, cálido, nada saturado.
  static const Color background = Color(0xFFFAF3E8);

  /// Superficie base de cards, sheets.
  static const Color surface = Color(0xFFFFF8F0);

  /// Superficie elevada (modales, dialogs).
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Superficie apagada (fondo de inputs, chips secundarios).
  static const Color surfaceMuted = Color(0xFFF5EDE0);

  /// Crema clara para tabs, fondos de inputs.
  static const Color creamLight = Color(0xFFFFF4E6);

  // ── Verde (usarlo con moderación) ─────────────────────────────────────────
  /// Verde principal — medio, menos saturado que antes.
  static const Color primary = Color(0xFF7A8C4A);

  /// Verde oscuro — para texto sobre verde o acciones destacadas.
  static const Color primaryDark = Color(0xFF4E6030);

  /// Verde muy suave — backgrounds, chips, badges.
  static Color primarySoft = const Color(0xFF7A8C4A).withValues(alpha: 0.10);

  // ── Marrón cacao — voz principal de la app ────────────────────────────────
  /// Color principal de texto — cacao cálido.
  static const Color text = Color(0xFF5C3D2E);

  /// Texto secundario (calculado en uso con alpha).
  static Color textMuted = const Color(0xFF5C3D2E).withValues(alpha: 0.55);

  // ── Acento ────────────────────────────────────────────────────────────────
  /// Naranja ámbar — botones CTA, badges, highlights.
  static const Color accent = Color(0xFFF59E2A);

  /// Acento apagado para iconos, tags secundarios.
  static Color accentMuted = const Color(0xFFD4852A);

  /// Acento muy suave (fondo de chips, hoverstates).
  static Color accentSoft = const Color(0xFFF59E2A).withValues(alpha: 0.15);

  // ── Fondo exterior (web) ──────────────────────────────────────────────────
  static const Color shellOutside = Color(0xFFEDE0CC);

  // ── Bordes y sombras ──────────────────────────────────────────────────────
  static Color outlineSoft = const Color(0xFF5C3D2E).withValues(alpha: 0.10);
  static Color outlineMedium = const Color(0xFF5C3D2E).withValues(alpha: 0.18);
  static Color shadowWarm = const Color(0xFF5C3D2E).withValues(alpha: 0.07);
  static Color shadowMedium = const Color(0xFF3D2B1F).withValues(alpha: 0.12);

  // ── Semántica financiera ──────────────────────────────────────────────────
  /// Deudas / pendiente — rojo ladrillo suave.
  static const Color owe = Color(0xFFC05C3D);

  /// A favor / cobrar — verde oliva.
  static const Color owed = Color(0xFF5C7030);
}
