import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/features/itinerario/models/ActividadItinerario.dart';
import 'package:choco/features/itinerario/models/DiaItinerario.dart';
import 'package:choco/features/itinerario/models/ItemItinerario.dart';
import 'package:choco/features/itinerario/models/Itinerario.dart';
import 'package:choco/features/itinerario/services/ItinerarioService.dart';
import 'package:choco/features/itinerario/widgets/calendar_view.dart';
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:choco/features/viajes/screens/resumen_actividades_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItinerarioScreen extends StatefulWidget {
  final int itinerarioId;
  final String? destinoKey;

  /// Si se proveen actividades seleccionadas desde el flujo (resumen → itinerario),
  /// se construye el itinerario con esas actividades en lugar de llamar al servicio.
  final List<ResumenActividad>? actividadesSeleccionadas;
  final int diasViaje;
  final String? nombreViaje;

  const ItinerarioScreen({
    super.key,
    required this.itinerarioId,
    this.destinoKey,
    this.actividadesSeleccionadas,
    this.diasViaje = 4,
    this.nombreViaje,
  });

  @override
  State<ItinerarioScreen> createState() => _ItinerarioScreenState();
}

class _ItinerarioScreenState extends State<ItinerarioScreen> {
  late Future<Itinerario> _itinerario;
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    if (widget.actividadesSeleccionadas != null &&
        widget.actividadesSeleccionadas!.isNotEmpty) {
      _itinerario = Future.value(_construirDesdeActividades(
        actividades: widget.actividadesSeleccionadas!,
        nombre: widget.nombreViaje ?? _nombreDelViaje,
        diasViaje: widget.diasViaje,
      ));
    } else {
      _itinerario =
          ItinerarioService().getItinerario(widget.itinerarioId);
    }
    _cargarBanner();
  }

  String get _nombreDelViaje {
    for (final v in kViajesMockRicos) {
      if (v.id == widget.itinerarioId) return v.nombreViaje;
    }
    return 'Itinerario del viaje';
  }

  Future<void> _cargarBanner() async {
    var dk = widget.destinoKey?.trim();
    if (dk == null || dk.isEmpty) {
      for (final v in kViajesMockRicos) {
        if (v.id == widget.itinerarioId) {
          dk = v.destinoKey;
          break;
        }
      }
    }
    dk ??= 'cartagena';
    try {
      final r = await AssetResolver.instance();
      final p = r.resolveDestinoImage(dk);
      if (mounted) setState(() => _bannerPath = p);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerario>(
      future: _itinerario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: Center(
              child: Text(
                'No pudimos cargar el itinerario',
                style: GoogleFonts.poppins(color: AppColors.text),
              ),
            ),
          );
        }

        final data = snapshot.data!;

        if (data.dias.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                title: Text(data.nombre,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.85)),
                    const SizedBox(height: 14),
                    Text(
                      'Choco está armando el plan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explora actividades para desbloquear tu itinerario con el grupo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.text.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: data.dias.length,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                data.nombre,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius:
                          BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.outlineSoft),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: AppColors.text,
                      unselectedLabelColor:
                          AppColors.text.withValues(alpha: 0.55),
                      labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: List.generate(
                        data.dias.length,
                        (i) => Tab(text: 'Día ${i + 1}'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_bannerPath != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm, 0, AppSpacing.sm, 6),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: AspectRatio(
                        aspectRatio: 2.8,
                        child: Image.asset(
                          normalizeFlutterAssetKey(_bannerPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) =>
                              Container(color: AppColors.creamLight),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(
                        AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outlineSoft),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.text.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBarView(
                      children: data.dias
                          .map((dia) => CalendarDayView(dia: dia))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Construir Itinerario desde actividades seleccionadas en el flujo
// ─────────────────────────────────────────────────────────────────────────────

/// Convierte el string de precio ("$45.000 COP" o "$45.000") a double.
double _parsePrecioDouble(String precio) {
  final clean = precio.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(clean) ?? 50000;
}

/// Convierte el string de duración ("3 h", "4h", "2.5 h") a minutos.
int _parseDuracionMin(String dur) {
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(dur);
  final horas = double.tryParse(match?.group(1) ?? '2') ?? 2.0;
  return (horas * 60).round();
}

Itinerario _construirDesdeActividades({
  required List<ResumenActividad> actividades,
  required String nombre,
  required int diasViaje,
}) {
  if (actividades.isEmpty) {
    return Itinerario(
      id: 7,
      nombre: nombre,
      presupuestoPromedioPersona: 0,
      dias: [],
    );
  }

  // Distribuir actividades en días lo más parejo posible
  final porDia = (actividades.length / diasViaje).ceil();
  final dias = <DiaItinerario>[];
  final fechaBase = DateTime(2026, 6, 20); // demo trip 20 jun

  int actIdx = 0;
  for (int d = 0; d < diasViaje && actIdx < actividades.length; d++) {
    final fecha = fechaBase.add(Duration(days: d));
    var horaActual = DateTime(fecha.year, fecha.month, fecha.day, 9, 0);

    final items = <ItemItinerario>[];
    final enEsteDia = porDia.clamp(1, actividades.length - actIdx);

    for (int k = 0; k < enEsteDia && actIdx < actividades.length; k++) {
      final act = actividades[actIdx];
      final durMin = _parseDuracionMin(act.duracion);
      final fin = horaActual.add(Duration(minutes: durMin));

      items.add(ItemItinerario(
        id: actIdx + 1,
        inicio: horaActual,
        fin: fin,
        estado: 'PROGRAMADA',
        actividad: ActividadItinerario(
          id: actIdx + 101,
          nombre: act.nombre,
          descripcion:
              'Actividad seleccionada por el grupo para $nombre.',
          costo: _parsePrecioDouble(act.precio),
          duracion: durMin,
          imagenes: [],
        ),
      ));

      // 45 min de margen entre actividades
      horaActual = fin.add(const Duration(minutes: 45));
      actIdx++;
    }

    if (items.isNotEmpty) {
      dias.add(DiaItinerario(fecha: fecha, items: items));
    }
  }

  // Presupuesto promedio = suma de costos
  final totalCosto = actividades
      .map((a) => _parsePrecioDouble(a.precio))
      .fold(0.0, (a, b) => a + b);

  return Itinerario(
    id: 7,
    nombre: nombre,
    presupuestoPromedioPersona: totalCosto,
    dias: dias,
  );
}
