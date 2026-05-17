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

class _ActividadItem extends StatefulWidget {
  final ItemItinerario item;
  final bool isLast;
  final int index;

  const _ActividadItem({
    required this.item,
    required this.isLast,
    required this.index,
  });

  @override
  State<_ActividadItem> createState() => _ActividadItemState();
}

class _ActividadItemState extends State<_ActividadItem> {
  late String _estadoLocal;

  @override
  void initState() {
    super.initState();
    _estadoLocal = widget.item.estado;
  }

  ItemItinerario get item => widget.item;
  bool get isLast => widget.isLast;
  int get index => widget.index;

  Color get _colorEstado {
    switch (_estadoLocal.toUpperCase()) {
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

  IconData get _iconEstado {
    switch (_estadoLocal.toUpperCase()) {
      case 'COMPLETADA':
        return Icons.check_rounded;
      case 'EN_CURSO':
        return Icons.play_arrow_rounded;
      case 'PROGRAMADA':
        return Icons.radio_button_unchecked_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String get _labelEstado {
    switch (_estadoLocal.toUpperCase()) {
      case 'COMPLETADA':
        return 'Completada';
      case 'EN_CURSO':
        return 'En curso';
      case 'PROGRAMADA':
        return 'Pendiente';
      default:
        return _estadoLocal;
    }
  }

  // Transporte mock basado en índice de la actividad para variedad
  String _transporteMock(int idx) {
    const opciones = [
      '~15 min en taxi',
      '~10 min caminando',
      '~20 min en metro',
      '~25 min en bus',
      '~12 min en taxi',
    ];
    return opciones[idx % opciones.length];
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
                    child: Icon(_iconEstado, size: 14, color: _colorEstado),
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
                    color: _esBloqueLogistico
                        ? AppColors.creamLight.withValues(alpha: 0.6)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _esBloqueLogistico
                          ? AppColors.outlineSoft.withValues(alpha: 0.5)
                          : AppColors.outlineSoft,
                    ),
                    boxShadow: _esBloqueLogistico
                        ? []
                        : [BoxShadow(color: AppColors.shadowWarm, blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.actividad.nombre,
                              style: _esBloqueLogistico
                                  ? AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65))
                                  : AppFonts.label(14.5, weight: FontWeight.w800),
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
                              _labelEstado,
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
                          !item.actividad.descripcion!.startsWith('Actividad seleccionada') &&
                          item.actividad.descripcion != 'Bloque logístico') ...[
                        const SizedBox(height: 6),
                        Text(
                          item.actividad.descripcion!,
                          style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.65), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (item.actividad.direccion != null) ...[
                        const SizedBox(height: 5),
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
                      // ── Transporte mock ────────────────────────────────────
                      if (index > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.directions_rounded, size: 12, color: AppColors.text.withValues(alpha: 0.38)),
                            const SizedBox(width: 4),
                            Text(
                              _transporteMock(index),
                              style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                      ],
                      // ── Acciones rápidas ───────────────────────────────────
                      // Solo para actividades principales (no bloques logísticos)
                      if (_estadoLocal.toUpperCase() != 'COMPLETADA' &&
                          !_esBloqueLogistico) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _AccionRapida(
                              label: 'Ya llegué',
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.green.shade700,
                              onTap: () {
                                setState(() => _estadoLocal = 'COMPLETADA');
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('¡Listo! Actividad marcada como completada.', style: AppFonts.body(13)),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ));
                              },
                            ),
                            _AccionRapida(
                              label: 'Voy tarde',
                              icon: Icons.schedule_rounded,
                              color: AppColors.owe,
                              onTap: () => _mostrarVoyTarde(context),
                            ),
                            _AccionRapida(
                              label: 'Ver ruta',
                              icon: Icons.alt_route_rounded,
                              color: AppColors.primaryDark,
                              onTap: () => _mostrarTransporte(context),
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

  bool get _esBloqueLogistico =>
      item.actividad.descripcion == 'Bloque logístico' ||
      item.actividad.nombre.startsWith('Desayuno') ||
      item.actividad.nombre.startsWith('Traslado') ||
      item.actividad.nombre.startsWith('Brunch') ||
      item.actividad.nombre.startsWith('Cena') ||
      item.actividad.nombre.startsWith('Noche');

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleActividadSheet(item: item),
    );
  }

  void _mostrarVoyTarde(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 36, color: AppColors.owe),
              const SizedBox(height: 12),
              Text('¿Vas tarde?', style: AppFonts.display(20)),
              const SizedBox(height: 8),
              Text(
                'Puedo mover "${item.actividad.nombre}" 30 minutos y ajustar la siguiente actividad automáticamente.',
                style: AppFonts.body(14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('¡Listo! Choco ajustó el plan.', style: AppFonts.body(13)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ));
                  },
                  child: const Text('Ajustar plan'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancelar', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.6))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarTransporte(BuildContext context) {
    const rutas = [
      ('Metro Línea A', '~22 min', Icons.directions_subway_rounded),
      ('Taxi directo', '~15 min', Icons.local_taxi_rounded),
      ('Uber / InDrive', '~18 min', Icons.directions_car_rounded),
      ('Caminata + bus', '~28 min', Icons.directions_walk_rounded),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.outlineSoft, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.alt_route_rounded, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text('Cómo llegar', style: AppFonts.title(17)),
            ]),
            const SizedBox(height: 6),
            Text('Ruta sugerida por Choco para llegar a "${item.actividad.nombre}"', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65))),
            const SizedBox(height: 14),
            ...rutas.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineSoft),
              ),
              child: Row(children: [
                Icon(r.$3, size: 20, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(child: Text(r.$1, style: AppFonts.label(13, weight: FontWeight.w700))),
                Text(r.$2, style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65))),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AccionRapida extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AccionRapida({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppFonts.label(11.5, weight: FontWeight.w700).copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
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
