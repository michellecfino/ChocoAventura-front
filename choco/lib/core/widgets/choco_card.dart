import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:flutter/material.dart';

/// Tarjeta base alineada con el design system.
class ChocoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const ChocoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final inner = Padding(padding: padding, child: child);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: AppColors.outlineSoft),
    );
    if (onTap == null) {
      return Material(
        color: color ?? Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        shape: shape,
        child: inner,
      );
    }
    return Material(
      color: color ?? Colors.white.withValues(alpha: 0.94),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: shape,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: inner,
      ),
    );
  }
}
