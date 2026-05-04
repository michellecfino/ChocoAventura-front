import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/features/itinerario/models/ItemItinerario.dart';
import 'package:flutter/material.dart';
import '../models/DiaItinerario.dart';

/// Vista de un día del itinerario como lista lineal de actividades.
/// Más legible y visualmente amena que una vista de calendario fijo.
class CalendarDayView extends StatelessWidget {
  final DiaItinerario dia;

  const CalendarDayView({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    if (dia.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined,
                  size: 44,
                  color: AppColors.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                'Sin actividades programadas',
                textAlign: TextAlign.center,
                style: AppFonts.body(15,
                    color: AppColors.text.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      );
    }

    final completadas = dia.items
        .where((i) => i.estado.toUpperCase() == 'COMPLETADA')
        .length;
    final total = dia.items.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      itemCount: dia.items.length + 1, // +1 para el encabezado del día
      itemBuilder: (context, i) {
        if (i == 0) {
          // ── Encabezado de progreso del día ──────────────────────────────
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatFecha(dia.fecha),
                        style: AppFonts.label(13, weight: FontWeight.w800)
                            .copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                    Text(
                      '$completadas/$total actividades',
                      style: AppFonts.body(12,
                          color: AppColors.text.withValues(alpha: 0.60)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? completadas / total : 0,
                    minHeight: 4,
                    backgroundColor: AppColors.outlineSoft,
                    color: completadas == total && total > 0
                        ? Colors.green.shade500
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }
        final item = dia.items[i - 1];
        final isLast = i - 1 == dia.items.length - 1;
        return _ActividadItem(item: item, isLast: isLast, index: i - 1);
      },
    );
  }

  String _formatFecha(DateTime fecha) {
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month]} ${fecha.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActividadItem extends StatelessWidget {
  final ItemItinerario item;
  final bool isLast;
  final int index;

  const _ActividadItem({
    required this.item,
    required this.isLast,
    required this.index,
  });

  Color get _colorEstado {
    switch (item.estado.toUpperCase()) {
      case 'COMPLETADA':
        return Colors.green.shade600;
      case 'EN_CURSO':
        return AppColors.accent;
      case 'PROGRAMADA':
        return AppColors.primary;
      default:
        return AppColors.text.withValues(alpha: 0.45);
    }
  }

  String get _iconEstado {
    switch (item.estado.toUpperCase()) {
      case 'COMPLETADA':
        return '✓';
      case 'EN_CURSO':
        return '▶';
      case 'PROGRAMADA':
        return '○';
      default:
        return '·';
    }
  }

  String get _horaFormato {
    final h = item.inicio.hour.toString().padLeft(2, '0');
    final m = item.inicio.minute.toString().padLeft(2, '0');
    final hf = item.fin.hour.toString().padLeft(2, '0');
    final mf = item.fin.minute.toString().padLeft(2, '0');
    return '$h:$m – $hf:$mf';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline vertical ───────────────────────────────────────────
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _colorEstado.withValues(alpha: 0.15),
                    border: Border.all(color: _colorEstado.withValues(alpha: 0.6)),
                  ),
                  child: Center(
                    child: Text(
                      _iconEstado,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _colorEstado,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.outlineSoft,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Card actividad ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: GestureDetector(
                onTap: () => _showDetail(context),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineSoft),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowWarm,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.actividad.nombre,
                              style: AppFonts.label(14.5, weight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _colorEstado.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.estado,
                              style: AppFonts.label(10.5, weight: FontWeight.w700)
                                  .copyWith(color: _colorEstado),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: AppColors.text.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            _horaFormato,
                            style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.72)),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.payments_outlined, size: 13, color: AppColors.text.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            '\$${item.actividad.costo.toStringAsFixed(0)} COP',
                            style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.72)),
                          ),
                        ],
                      ),
                      if (item.actividad.descripcion != null &&
                          item.actividad.descripcion!.isNotEmpty &&
                          !item.actividad.descripcion!.startsWith('Actividad seleccionada')) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.actividad.descripcion!,
                          style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.65), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.actividad.direccion != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.place_rounded, size: 13, color: AppColors.text.withValues(alpha: 0.45)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.actividad.direccion!,
                                style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.55)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleActividadSheet(item: item),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetalleActividadSheet extends StatelessWidget {
  final ItemItinerario item;

  const _DetalleActividadSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(24));
    final actividad = item.actividad;

    Color colorEstado(String estado) {
      switch (estado.toUpperCase()) {
        case 'COMPLETADA':
          return Colors.green.shade600;
        case 'EN_CURSO':
          return AppColors.accent;
        default:
          return AppColors.primary;
      }
    }

    final String hora =
        '${item.inicio.hour.toString().padLeft(2, '0')}:${item.inicio.minute.toString().padLeft(2, '0')}'
        ' – '
        '${item.fin.hour.toString().padLeft(2, '0')}:${item.fin.minute.toString().padLeft(2, '0')}';

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: AppColors.shadowWarm, blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.text.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                if (actividad.imagenes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      actividad.imagenes.first.url,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Container(
                        height: 180,
                        color: AppColors.surfaceMuted,
                        child: Icon(Icons.image_outlined, size: 44, color: AppColors.text.withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(actividad.nombre, style: AppFonts.display(20)),
                    ),
                    if (actividad.calificacionPromedio != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${actividad.calificacionPromedio}',
                              style: AppFonts.label(13, weight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorEstado(item.estado).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorEstado(item.estado).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    item.estado,
                    style: AppFonts.label(12, weight: FontWeight.w700)
                        .copyWith(color: colorEstado(item.estado)),
                  ),
                ),
                const SizedBox(height: 16),
                if (actividad.descripcion != null) ...[
                  Text(actividad.descripcion!, style: AppFonts.body(14, height: 1.5)),
                  const SizedBox(height: 16),
                ],
                _bloque(Icons.access_time_rounded, 'Horario', hora),
                _bloque(Icons.payments_outlined, 'Costo por persona', '\$${actividad.costo.toStringAsFixed(0)} COP'),
                if (actividad.direccion != null)
                  _bloque(Icons.place_rounded, 'Dirección', actividad.direccion!),
                if (actividad.preciosDetallados != null)
                  _bloque(Icons.info_outline_rounded, 'Precios', actividad.preciosDetallados!),
                if (actividad.fuente != null)
                  _bloque(Icons.bookmark_outlined, 'Fuente', actividad.fuente!),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bloque(IconData icon, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppFonts.label(12, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(valor, style: AppFonts.body(13.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
