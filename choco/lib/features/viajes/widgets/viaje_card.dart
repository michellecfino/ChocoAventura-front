import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/widgets/destino_visual.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ViajeCard extends StatelessWidget {
  final GrupoViajeModel viaje;
  final String? bannerAssetPath;
  final VoidCallback? onVerDetalle;
  final VoidCallback? onCtaPrincipal;

  const ViajeCard({
    super.key,
    required this.viaje,
    this.bannerAssetPath,
    this.onVerDetalle,
    this.onCtaPrincipal,
  });

  int? get _dias {
    // Mock simple: si hay fechas texto, estimar 4 días por defecto para UI.
    if (viaje.fechaInicio != null && viaje.fechaFin != null) return 4;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final banner = bannerAssetPath;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        elevation: 2,
        shadowColor: AppColors.text.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onCtaPrincipal ?? onVerDetalle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 118,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (banner != null)
                      BackendImage(
                        source: banner,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => DestinoCoverDecorada(
                          titulo: viaje.destinoNombre,
                          height: 118,
                        ),
                      )
                    else
                      DestinoCoverDecorada(
                        titulo: viaje.destinoNombre,
                        height: 118,
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 10,
                      child: Row(
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
                              style: AppFonts.label(10.5, weight: FontWeight.w800).copyWith(color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            viaje.destinoNombre,
                            style: AppFonts.label(11, weight: FontWeight.w700).copyWith(color: Colors.white.withValues(alpha: 0.92)),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viaje.nombreViaje,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.display(17).copyWith(
                              color: Colors.white,
                              height: 1.1,
                              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${viaje.fechaInicio ?? '—'} → ${viaje.fechaFin ?? '—'}',
                            style: AppFonts.body(11.5, color: Colors.white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: AppColors.surfaceElevated,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.place_rounded, size: 17, color: AppColors.primary.withValues(alpha: 0.9)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            viaje.ciudadDepartamento,
                            style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.88)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded, size: 16, color: AppColors.text.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          '${viaje.participantes} ${viaje.participantes == 1 ? 'persona' : 'personas'}',
                          style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.72)),
                        ),
                        if (_dias != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.date_range_rounded, size: 16, color: AppColors.text.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '$_dias días',
                            style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.72)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fase: ${viaje.faseActual.etiquetaCorta}',
                      style: AppFonts.label(11.5, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            viaje.codigoInvitacion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.label(12.5, weight: FontWeight.w800).copyWith(
                              color: AppColors.text.withValues(alpha: 0.88),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Copiar código',
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () async {
                            final ctx = context;
                            try {
                              await Clipboard.setData(ClipboardData(text: viaje.codigoInvitacion));
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Código copiado', style: AppFonts.body(14)),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (_) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('No se pudo copiar. Selecciona el código manualmente.', style: AppFonts.body(14)),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Más información',
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: onVerDetalle,
                          icon: const Icon(Icons.info_outline_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: onCtaPrincipal,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              viaje.faseActual.ctaPrincipal,
                              style: AppFonts.label(13, weight: FontWeight.w800),
                            ),
                          ),
                        ),
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
