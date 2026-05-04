import 'package:choco/app/colors.dart';
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:flutter/material.dart';

/// Imágenes reales en `assets/choco/` (orden de preferencia).
const String kChocoPrimaryAsset = 'assets/choco/saludando.png';

const List<String> kChocoAssetCandidates = [
  kChocoPrimaryAsset,
  'assets/choco/sonrie.png',
  'assets/choco/choco_icon.png',
  'assets/choco/logo.png',
  'assets/choco/hablando.png',
  'assets/choco/usando_app.png',
];

List<String> _rotatedCandidates(int start) {
  if (kChocoAssetCandidates.isEmpty) return const [];
  final s = start.abs() % kChocoAssetCandidates.length;
  if (s == 0) return List<String>.from(kChocoAssetCandidates);
  return [
    ...kChocoAssetCandidates.sublist(s),
    ...kChocoAssetCandidates.sublist(0, s),
  ];
}

/// Ilustración de Choco desde assets reales; si falla, icono de marca (sin fotos genéricas).
class ChocoIllustration extends StatelessWidget {
  final double size;
  final double borderRadius;
  final BoxFit fit;

  /// Cambia el orden de prueba de assets (variación visual entre tarjetas).
  final int? variantSeed;

  /// Solo intenta el asset principal y pocos fallbacks seguros.
  final bool preferPrimaryOnly;

  /// Si no es null, se muestra primero (p. ej. Choco «hablando» mientras escucha).
  final String? overrideAsset;

  const ChocoIllustration({
    super.key,
    this.size = 44,
    this.borderRadius = 10,
    this.fit = BoxFit.contain,
    this.variantSeed,
    this.preferPrimaryOnly = false,
    this.overrideAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (overrideAsset != null && overrideAsset!.isNotEmpty) {
      final chain = [overrideAsset!, ...kChocoAssetCandidates.where((e) => e != overrideAsset)];
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _AssetFallbackChain(candidates: chain, index: 0, size: size, fit: fit),
        ),
      );
    }

    if (preferPrimaryOnly) {
      final safe = <String>[kChocoPrimaryAsset, ...kChocoAssetCandidates.where((e) => e != kChocoPrimaryAsset)];
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: _AssetFallbackChain(candidates: safe, index: 0, size: size, fit: fit),
        ),
      );
    }

    final rotated = _rotatedCandidates(variantSeed ?? 0);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _AssetFallbackChain(
          candidates: rotated.isNotEmpty ? rotated : kChocoAssetCandidates,
          index: 0,
          size: size,
          fit: fit,
        ),
      ),
    );
  }
}

class _AssetFallbackChain extends StatelessWidget {
  final List<String> candidates;
  final int index;
  final double size;
  final BoxFit fit;

  const _AssetFallbackChain({
    required this.candidates,
    required this.index,
    required this.size,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (index >= candidates.length) {
      return _elegantMissing(size);
    }
    return Image.asset(
      normalizeFlutterAssetKey(candidates[index]),
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) => _AssetFallbackChain(
        candidates: candidates,
        index: index + 1,
        size: size,
        fit: fit,
      ),
    );
  }

  static Widget _elegantMissing(double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.eco_rounded,
        size: size * 0.48,
        color: AppColors.primary.withValues(alpha: 0.65),
      ),
    );
  }
}
