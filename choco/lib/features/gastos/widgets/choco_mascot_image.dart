import 'package:flutter/material.dart';

import 'choco_illustration.dart';

/// Wrapper retrocompatible: usa ilustraciones reales desde `assets/choco/` vía [ChocoIllustration].
class ChocoMascotImage extends StatelessWidget {
  final double size;
  final bool showBorder;

  const ChocoMascotImage({
    super.key,
    this.size = 72,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = ChocoIllustration(
      size: showBorder ? size - 4 : size,
      borderRadius: size > 50 ? 12 : 8,
    );
    if (!showBorder) return SizedBox(width: size, height: size, child: child);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
