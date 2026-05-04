import 'package:choco/app/colors.dart';
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/features/gastos/widgets/choco_illustration.dart';
import 'package:flutter/material.dart';

/// Logo fijo de Choco para el botón central del dock (`assets/choco/logo.png`).
class ChocoNavLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;

  const ChocoNavLogo({super.key, this.size = 48, this.fit = BoxFit.contain});

  static const String kLogoPath = 'assets/choco/logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 2),
          color: Colors.transparent,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            normalizeFlutterAssetKey(kLogoPath),
            width: size,
            height: size,
            fit: fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, e, s) => ChocoIllustration(
              size: size - 6,
              borderRadius: (size - 6) / 2,
              fit: BoxFit.contain,
              preferPrimaryOnly: true,
            ),
          ),
        ),
      ),
    );
  }
}
