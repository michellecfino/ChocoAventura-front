import 'package:choco/app/colors.dart';
import 'package:flutter/material.dart';

/// En pantallas anchas centra la app (~móvil).
class MobileAppFrame extends StatelessWidget {
  final Widget? child;

  const MobileAppFrame({super.key, required this.child});

  /// Ancho tipo móvil (~iPhone); más estrecho que antes para sensación “phone frame”.
  static const double maxWidth = 418;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final w = MediaQuery.sizeOf(context).width;
    final wide = w > maxWidth + 32;
    if (!wide) {
      return ColoredBox(color: AppColors.background, child: content);
    }
    return ColoredBox(
      color: AppColors.shellOutside,
      child: Center(
        child: Container(
          width: maxWidth,
          height: MediaQuery.sizeOf(context).height,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.text.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowWarm,
                blurRadius: 40,
                offset: const Offset(0, 18),
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
