import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:flutter/material.dart';

/// Fondo ilustrado cuando no hay foto de destino (evita gris plano o Choco como banner).
class DestinoCoverDecorada extends StatelessWidget {
  final String? titulo;
  final double height;

  const DestinoCoverDecorada({
    super.key,
    this.titulo,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.55),
              AppColors.accentMuted.withValues(alpha: 0.75),
              AppColors.primaryDark.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -20,
              top: -16,
              child: Icon(Icons.explore_rounded, size: height * 0.85, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, color: Colors.white.withValues(alpha: 0.92), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      titulo ?? 'Tu destino',
                      textAlign: TextAlign.center,
                      style: AppFonts.title(15).copyWith(color: Colors.white, shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choco está preparando las fotos del viaje',
                      textAlign: TextAlign.center,
                      style: AppFonts.body(12, color: Colors.white.withValues(alpha: 0.88)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
