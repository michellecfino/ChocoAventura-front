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

/// Bloques logísticos fijos por momento del día para enriquecer cada día.
const _bloquesManana = [
  ('Desayuno en el hotel', 30, 0.0),
  ('Desayuno en café local', 45, 15000.0),
  ('Brunch en restaurante del barrio', 60, 25000.0),
];
const _bloquesTraslado = [
  ('Traslado · Metro + caminata', 30, 0.0),
  ('Traslado · Taxi al punto', 20, 12000.0),
  ('Traslado · Uber al siguiente lugar', 25, 14000.0),
];
const _bloquesTarde = [
  ('Tarde libre en el centro', 90, 0.0),
  ('Compras y souvenirs del destino', 60, 20000.0),
  ('Paseo por el barrio histórico', 75, 0.0),
  ('Café y vista desde terraza', 50, 12000.0),
];
const _bloquesRelleno = [
  ('Descanso en el hotel', 60, 0.0),
  ('Mirador panorámico', 45, 0.0),
  ('Foto en el punto icónico', 30, 0.0),
  ('Snack típico del lugar', 30, 12000.0),
];
const _bloquesNoche = [
  ('Cena en restaurante local', 75, 45000.0),
  ('Noche en el parque principal', 60, 0.0),
  ('Plan nocturno: bar o terraza', 90, 30000.0),
];

Itinerario _construirDesdeActividades({
  required List<ResumenActividad> actividades,
  required String nombre,
  required int diasViaje,
}) {
  if (actividades.isEmpty) {
    return Itinerario(id: 7, nombre: nombre, presupuestoPromedioPersona: 0, dias: []);
  }

  // Distribuir actividades principales de forma pareja entre los días
  final porDia = (actividades.length / diasViaje).ceil().clamp(1, 3);
  final dias = <DiaItinerario>[];
  final fechaBase = DateTime(2026, 6, 20);

  int actIdx = 0;
  int itemId = 1;

  for (int d = 0; d < diasViaje; d++) {
    final fecha = fechaBase.add(Duration(days: d));
    var hora = DateTime(fecha.year, fecha.month, fecha.day, 8, 0);
    final items = <ItemItinerario>[];

    // ── Bloque 1: Desayuno ────────────────────────────────────────
    final desayuno = _bloquesManana[d % _bloquesManana.length];
    final finDesayuno = hora.add(Duration(minutes: desayuno.$2));
    items.add(ItemItinerario(
      id: itemId++,
      inicio: hora,
      fin: finDesayuno,
      estado: 'PROGRAMADA',
      actividad: ActividadItinerario(
        id: itemId + 200,
        nombre: desayuno.$1,
        descripcion: 'Bloque logístico',
        costo: desayuno.$3,
        duracion: desayuno.$2,
        imagenes: [],
      ),
    ));
    hora = finDesayuno.add(const Duration(minutes: 15));

    // ── Actividades principales del día ───────────────────────────
    final enEsteDia = (actIdx < actividades.length) ? porDia.clamp(1, actividades.length - actIdx) : 0;
    for (int k = 0; k < enEsteDia && actIdx < actividades.length; k++) {
      final act = actividades[actIdx];
      final durMin = _parseDuracionMin(act.duracion);
      final fin = hora.add(Duration(minutes: durMin));
      items.add(ItemItinerario(
        id: itemId++,
        inicio: hora,
        fin: fin,
        estado: 'PROGRAMADA',
        actividad: ActividadItinerario(
          id: actIdx + 101,
          nombre: act.nombre,
          descripcion: act.nombre,
          costo: _parsePrecioDouble(act.precio),
          duracion: durMin,
          imagenes: [],
        ),
      ));
      // Traslado siempre (entre actividades o hacia el siguiente bloque)
      final traslado = _bloquesTraslado[(actIdx + k) % _bloquesTraslado.length];
      final finTraslado = fin.add(Duration(minutes: traslado.$2));
      items.add(ItemItinerario(
        id: itemId++,
        inicio: fin,
        fin: finTraslado,
        estado: 'PROGRAMADA',
        actividad: ActividadItinerario(
          id: itemId + 300,
          nombre: traslado.$1,
          descripcion: 'Bloque logístico',
          costo: traslado.$3,
          duracion: traslado.$2,
          imagenes: [],
        ),
      ));
      hora = finTraslado.add(const Duration(minutes: 10));
      actIdx++;
    }

    // ── Bloque tarde libre (si hay espacio antes de las 19:00) ────
    if (hora.hour < 16) {
      final tarde = _bloquesTarde[d % _bloquesTarde.length];
      final finTarde = hora.add(Duration(minutes: tarde.$2));
      items.add(ItemItinerario(
        id: itemId++,
        inicio: hora,
        fin: finTarde,
        estado: 'PROGRAMADA',
        actividad: ActividadItinerario(
          id: itemId + 500,
          nombre: tarde.$1,
          descripcion: 'Bloque logístico',
          costo: tarde.$3,
          duracion: tarde.$2,
          imagenes: [],
        ),
      ));
      hora = finTarde.add(const Duration(minutes: 20));
    }

    // ── Bloque final: Noche ───────────────────────────────────────
    final nocheIdx = d % _bloquesNoche.length;
    final noche = _bloquesNoche[nocheIdx];
    if (hora.hour < 19) {
      hora = DateTime(fecha.year, fecha.month, fecha.day, 19, 0);
    }
    final finNoche = hora.add(Duration(minutes: noche.$2));
    final nocheItem = ItemItinerario(
      id: itemId++,
      inicio: hora,
      fin: finNoche,
      estado: 'PROGRAMADA',
      actividad: ActividadItinerario(
        id: itemId + 400,
        nombre: noche.$1,
        descripcion: 'Bloque logístico',
        costo: noche.$3,
        duracion: noche.$2,
        imagenes: [],
      ),
    );
    items.add(nocheItem);

    // ── Garantía: mínimo 5 bloques por día ────────────────────────
    // Si quedan < 5, insertamos rellenos ligeros justo antes de la noche.
    int rellenoIdx = d;
    while (items.length < 5) {
      final r = _bloquesRelleno[rellenoIdx % _bloquesRelleno.length];
      // Posicionar entre la penúltima (último item antes de la noche) y la noche.
      final beforeIndex = items.length - 1; // índice de noche
      final inicioRelleno = items[beforeIndex - 1].fin.add(const Duration(minutes: 10));
      final finRelleno = inicioRelleno.add(Duration(minutes: r.$2));
      items.insert(beforeIndex, ItemItinerario(
        id: itemId++,
        inicio: inicioRelleno,
        fin: finRelleno,
        estado: 'PROGRAMADA',
        actividad: ActividadItinerario(
          id: itemId + 600,
          nombre: r.$1,
          descripcion: 'Bloque logístico',
          costo: r.$3,
          duracion: r.$2,
          imagenes: [],
        ),
      ));
      rellenoIdx++;
    }

    dias.add(DiaItinerario(fecha: fecha, items: items));
  }

  final totalCosto = actividades.map((a) => _parsePrecioDouble(a.precio)).fold(0.0, (a, b) => a + b);

  return Itinerario(
    id: 7,
    nombre: nombre,
    presupuestoPromedioPersona: totalCosto,
    dias: dias,
  );
}
