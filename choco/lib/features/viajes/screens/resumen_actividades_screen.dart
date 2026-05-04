import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/features/itinerario/screens/ItinerarioScreen.dart';
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:flutter/material.dart';

/// Actividad elegida para mostrar en el resumen y construir el itinerario.
class ResumenActividad {
  final String nombre;
  final String categoria; // emoji de la categoría
  final String precio;
  final String duracion;
  final String imagenPath;

  const ResumenActividad({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.duracion,
    this.imagenPath = '',
  });
}

/// Pantalla resumen tras el ranking: muestra las actividades elegidas
/// con una breve explicación y CTA para ir al itinerario.
class ResumenActividadesScreen extends StatelessWidget {
  final String? viajeId;
  final String? nombreViaje;
  final String destinoKey;
  final List<ResumenActividad> actividadesElegidas;
  final int diasViaje;

  const ResumenActividadesScreen({
    super.key,
    this.viajeId,
    this.nombreViaje,
    required this.destinoKey,
    required this.actividadesElegidas,
    this.diasViaje = 4,
  });

  @override
  Widget build(BuildContext context) {
    final viaje = viajeId != null
        ? kViajesMockRicos.where((v) => '${v.id}' == viajeId).firstOrNull
        : null;
    final dias = viaje != null ? 4 : diasViaje;
    final porDia = actividadesElegidas.isNotEmpty
        ? (actividadesElegidas.length / dias).ceil()
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── App bar ───────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.text,
            elevation: 0,
            pinned: false,
            expandedHeight: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),

          // ── Encabezado ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '✦ Plan listo',
                      style: AppFonts.label(12, weight: FontWeight.w700)
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Estas son las\nactividades elegidas',
                    style: AppFonts.display(24).copyWith(height: 1.15),
                  ),
                  if (nombreViaje != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      nombreViaje!,
                      style: AppFonts.body(14,
                          color: AppColors.text.withValues(alpha: 0.60)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Stats (ARRIBA de la lista) ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _StatsResumen(
                totalActividades: actividadesElegidas.length,
                diasViaje: dias,
                porDia: porDia,
              ),
            ),
          ),

          // ── Mensaje Choco (conciso) ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.creamLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🍫', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Choco armó esta selección según el grupo, el swipe y tus prioridades.',
                        style: AppFonts.body(13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Lista de actividades ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ActividadResumenCard(
                  actividad: actividadesElegidas[i],
                  posicion: i + 1,
                ),
                childCount: actividadesElegidas.length,
              ),
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        final id = int.tryParse(viajeId ?? '') ?? 1;
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(
                          builder: (_) => ItinerarioScreen(
                            itinerarioId: id,
                            destinoKey: destinoKey,
                            actividadesSeleccionadas: actividadesElegidas,
                            diasViaje: dias,
                            nombreViaje: nombreViaje,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.map_rounded, size: 22),
                      label: Text(
                        'Ver itinerario',
                        style: AppFonts.label(16, weight: FontWeight.w900)
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(
                      'Volver al inicio',
                      style:
                          AppFonts.label(14, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActividadResumenCard extends StatelessWidget {
  final ResumenActividad actividad;
  final int posicion;

  const _ActividadResumenCard(
      {required this.actividad, required this.posicion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineSoft),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadowWarm,
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  actividad.categoria.isNotEmpty
                      ? actividad.categoria
                      : '✨',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(actividad.nombre,
                      style:
                          AppFonts.label(14, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 13,
                          color: AppColors.text.withValues(alpha: 0.55)),
                      const SizedBox(width: 3),
                      Text(actividad.precio,
                          style: AppFonts.body(12,
                              color:
                                  AppColors.text.withValues(alpha: 0.65))),
                      const SizedBox(width: 10),
                      Icon(Icons.schedule_outlined,
                          size: 13,
                          color: AppColors.text.withValues(alpha: 0.55)),
                      const SizedBox(width: 3),
                      Text(actividad.duracion,
                          style: AppFonts.body(12,
                              color: AppColors.text
                                  .withValues(alpha: 0.65))),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#$posicion',
                style: AppFonts.label(12, weight: FontWeight.w800)
                    .copyWith(color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsResumen extends StatelessWidget {
  final int totalActividades;
  final int diasViaje;
  final int porDia;

  const _StatsResumen({
    required this.totalActividades,
    required this.diasViaje,
    required this.porDia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(valor: '$totalActividades', etiqueta: 'actividades'),
          _Divider(),
          _StatItem(valor: '$diasViaje', etiqueta: 'días'),
          _Divider(),
          _StatItem(valor: '~$porDia', etiqueta: 'por día'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor;
  final String etiqueta;
  const _StatItem({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: AppFonts.display(22)
                .copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 2),
        Text(etiqueta,
            style: AppFonts.body(11.5,
                color: AppColors.text.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.outlineSoft);
  }
}
