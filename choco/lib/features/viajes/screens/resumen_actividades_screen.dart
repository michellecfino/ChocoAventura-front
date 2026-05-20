import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/itinerario/models/Itinerario.dart';
import 'package:choco/features/itinerario/screens/ItinerarioScreen.dart';
import 'package:choco/features/itinerario/services/ItinerarioService.dart';
import 'package:flutter/material.dart';

class ResumenActividad {
  final String nombre;
  final String categoria;
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

class ResumenActividadesScreen extends StatefulWidget {
  final String? viajeId;
  final int? itinerarioId;
  final String? nombreViaje;
  final String destinoKey;
  final List<ResumenActividad> actividadesElegidas;
  final int diasViaje;

  const ResumenActividadesScreen({
    super.key,
    this.viajeId,
    this.itinerarioId,
    this.nombreViaje,
    required this.destinoKey,
    required this.actividadesElegidas,
    this.diasViaje = 4,
  });

  @override
  State<ResumenActividadesScreen> createState() => _ResumenActividadesScreenState();
}

class _ResumenActividadesScreenState extends State<ResumenActividadesScreen> {
  late Future<Itinerario?> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargarItinerario();
  }

  Future<Itinerario?> _cargarItinerario() async {
    final usuarioId = UserSession().user?.id;
    if (widget.itinerarioId != null) {
      return const ItinerarioService().getItinerario(widget.itinerarioId!, usuarioId: usuarioId);
    }
    final grupoId = int.tryParse(widget.viajeId ?? '');
    if (grupoId != null) {
      try {
        return const ItinerarioService().getItinerarioActualPorGrupo(grupoViajeId: grupoId, usuarioId: usuarioId);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerario?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final itinerario = snap.data;
        final actividades = itinerario == null
            ? widget.actividadesElegidas
            : _actividadesDesdeItinerario(itinerario);
        final dias = itinerario?.dias.length ?? widget.diasViaje;
        final porDia = actividades.isNotEmpty && dias > 0 ? (actividades.length / dias).ceil() : 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Itinerario creado', style: AppFonts.title(17)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.text,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 42),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✦ Plan guardado en backend',
                  style: AppFonts.label(12, weight: FontWeight.w700).copyWith(color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 12),
              Text('Estas son las\nactividades elegidas', style: AppFonts.display(24).copyWith(height: 1.15)),
              if ((widget.nombreViaje ?? itinerario?.nombre) != null) ...[
                const SizedBox(height: 4),
                Text(widget.nombreViaje ?? itinerario!.nombre, style: AppFonts.body(14, color: AppColors.text.withValues(alpha: 0.60))),
              ],
              const SizedBox(height: 16),
              _StatsResumen(totalActividades: actividades.length, diasViaje: dias, porDia: porDia),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
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
                        itinerario == null
                            ? 'Este resumen usa los datos recibidos por la pantalla anterior.'
                            : 'Choco armó y guardó este itinerario usando el swipe, la Mesa de Choco y el knapsack del backend.',
                        style: AppFonts.body(13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snap.hasError)
                _MensajeError(texto: 'No pude leer el itinerario desde backend. ${snap.error}')
              else if (actividades.isEmpty)
                _MensajeError(texto: 'El itinerario existe, pero no tiene actividades programadas todavía.')
              else
                ...List.generate(actividades.length, (i) => _ActividadResumenCard(actividad: actividades[i], posicion: i + 1)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: itinerario == null
                      ? null
                      : () {
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => ItinerarioScreen(
                              itinerarioId: itinerario.id,
                              destinoKey: widget.destinoKey,
                              nombreViaje: widget.nombreViaje ?? itinerario.nombre,
                            ),
                          ));
                        },
                  icon: const Icon(Icons.map_rounded, size: 22),
                  label: Text('Ver itinerario', style: AppFonts.label(16, weight: FontWeight.w900).copyWith(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text('Volver al inicio', style: AppFonts.label(14, weight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ResumenActividad> _actividadesDesdeItinerario(Itinerario itinerario) {
    final resultado = <ResumenActividad>[];
    for (final dia in itinerario.dias) {
      for (final item in dia.items) {
        resultado.add(ResumenActividad(
          nombre: item.actividad.nombre,
          categoria: '✨',
          precio: formatoCopLocal(item.actividad.costo),
          duracion: '${(item.actividad.duracion / 60).toStringAsFixed(item.actividad.duracion % 60 == 0 ? 0 : 1)} h',
        ));
      }
    }
    return resultado;
  }
}

String formatoCopLocal(double valor) {
  final n = valor.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < n.length; i++) {
    final remaining = n.length - i;
    buffer.write(n[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '\$${buffer.toString()}';
}

class _ActividadResumenCard extends StatelessWidget {
  final ResumenActividad actividad;
  final int posicion;

  const _ActividadResumenCard({required this.actividad, required this.posicion});

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
          boxShadow: [BoxShadow(color: AppColors.shadowWarm, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(actividad.categoria.isNotEmpty ? actividad.categoria : '✨', style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(actividad.nombre, style: AppFonts.label(14, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('${actividad.precio} · ${actividad.duracion}', style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.65))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text('#$posicion', style: AppFonts.label(12, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark)),
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

  const _StatsResumen({required this.totalActividades, required this.diasViaje, required this.porDia});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: AppColors.creamLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outlineSoft)),
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
        Text(valor, style: AppFonts.display(22).copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 2),
        Text(etiqueta, style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: AppColors.outlineSoft);
}

class _MensajeError extends StatelessWidget {
  final String texto;
  const _MensajeError({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
      child: Text(texto, style: AppFonts.body(13, height: 1.4)),
    );
  }
}
