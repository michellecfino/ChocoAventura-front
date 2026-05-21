import 'dart:math' as math;

import 'package:choco/app/colors.dart';
import 'package:flutter/material.dart';

/// Marco centrado tipo **iPhone 15 Pro Max** (~430 × ~932 lógicos): ancho fijo y alto proporcional.
class MobileAppFrame extends StatelessWidget {
  final Widget? child;

  const MobileAppFrame({super.key, required this.child});

  /// Ancho lógico cercano a iPhone 15 Pro Max (430 pt).
  static const double maxWidth = 428;

  /// Relación alto/ancho aproximada del 15 Pro Max (pantalla útil).
  static const double phoneAspectRatio = 932 / 430;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final wide = w > maxWidth + 32;

    if (!wide) {
      return ColoredBox(color: AppColors.background, child: content);
    }

    final targetHeight = math.min(
      size.height * 0.96,
      maxWidth * phoneAspectRatio,
    );

    return ColoredBox(
      color: AppColors.shellOutside,
      child: Center(
        child: Container(
          width: maxWidth,
          height: targetHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.text.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowWarm,
                blurRadius: 44,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      ),
    );
  }
}
