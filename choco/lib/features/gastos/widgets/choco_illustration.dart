import 'package:choco/app/colors.dart';
import 'package:flutter/material.dart';

/// Solo ilustraciones de Choco; sin mapas/fotos genéricas que se vean “rotas” o fuera de contexto.
const List<String> kChocoAssetCandidates = [
  'lib/assets/choco_reference.png',
  'lib/assets/choco_icon.png',
  'lib/assets/CHOCO_Logo.png',
  'lib/assets/choco_grupo.png',
  'lib/assets/choco_estresado.png',
  'assets/choco/choco_icon.png',
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

/// Ilustración real de Choco; si ningún asset existe, icono oliva discreto (sin dibujos improvisados).
class ChocoIllustration extends StatelessWidget {
  final double size;
  final double borderRadius;
  final BoxFit fit;

  /// Cambia el orden de prueba de assets (variación visual entre tarjetas).
  final int? variantSeed;

  const ChocoIllustration({
    super.key,
    this.size = 44,
    this.borderRadius = 10,
    this.fit = BoxFit.contain,
    this.variantSeed,
  });

  @override
  Widget build(BuildContext context) {
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
      candidates[index],
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
