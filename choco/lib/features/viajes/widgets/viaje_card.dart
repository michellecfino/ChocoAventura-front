import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/features/gastos/widgets/choco_illustration.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViajeCard extends StatelessWidget {
  final GrupoViajeModel viaje;
  final VoidCallback? onTap;

  const ViajeCard({
    super.key,
    required this.viaje,
    this.onTap,
  });

  LinearGradient _coverGradient() {
    final h = viaje.destino.hashCode.abs();
    final t = (h % 100) / 100.0;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(AppColors.primary, AppColors.background, 0.15)!,
        Color.lerp(AppColors.primary, const Color(0xFF8B9048), 0.35 + t * 0.15)!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final seed = viaje.nombre.hashCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        elevation: 2,
        shadowColor: AppColors.text.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 96,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(decoration: BoxDecoration(gradient: _coverGradient())),
                    Positioned(
                      right: -6,
                      bottom: -8,
                      child: Opacity(
                        opacity: 0.35,
                        child: ChocoIllustration(size: 96, borderRadius: 18, variantSeed: seed),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              viaje.estadoDisplay,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            viaje.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white.withValues(alpha: 0.96),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.place_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            viaje.destino,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded, size: 18, color: AppColors.text.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Text(
                          '${viaje.participantes} ${viaje.participantes == 1 ? 'persona' : 'personas'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppColors.text.withValues(alpha: 0.72),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: AppColors.primary.withValues(alpha: 0.65)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
