import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart' show AssetResolver;
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/features/gastos/widgets/choco_illustration.dart';
import 'package:choco/features/viajes/screens/resumen_actividades_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos internos
// ─────────────────────────────────────────────────────────────────────────────

/// Actividad candidata para usar internamente al construir el plan final.
class _ActividadCandidata {
  final String nombre;
  final String emoji;
  final String precio;
  final String duracion;
  final double score;

  const _ActividadCandidata({
    required this.nombre,
    required this.emoji,
    required this.precio,
    required this.duracion,
    required this.score,
  });
}

/// Categoría con estadísticas resumidas y sus actividades candidatas.
class _CategoriaRanking {
  final String id;
  final String nombre;
  final String emoji;
  final String precioPromedio;
  final String duracionPromedio;
  final List<_ActividadCandidata> actividades;

  const _CategoriaRanking({
    required this.id,
    required this.nombre,
    required this.emoji,
    required this.precioPromedio,
    required this.duracionPromedio,
    required this.actividades,
  });

  int get cantidad => actividades.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Datos Medellín
// ─────────────────────────────────────────────────────────────────────────────

/// Pool completo de actividades con (nombre, categoría, emoji, precio, duración, likes, rating).
/// Las actividades ya agrupadas se convierten en categorías para el ranking.
List<_CategoriaRanking> _calcularCategoriasMedellin() {
  // (nombre, precio COP, duración horas, likes, rating)
  final byCategory = <String, List<_ActividadCandidata>>{
    'Naturaleza y aventura': [
      _ActividadCandidata(nombre: 'Excursión a Cascadas',       emoji: '🌊', precio: r'$75.000', duracion: '5 h', score: 4 * 2.0 + 4.7 * 10),
      _ActividadCandidata(nombre: 'Parapente Cerca de Medellín', emoji: '🪂', precio: r'$130.000', duracion: '3 h', score: 3 * 2.0 + 4.8 * 10),
    ],
    'Gastronomía': [
      _ActividadCandidata(nombre: 'Clase de Cocina Antioqueña', emoji: '🍲', precio: r'$60.000', duracion: '3 h', score: 4 * 2.0 + 4.6 * 10),
      _ActividadCandidata(nombre: 'Café de Especialidad',       emoji: '☕', precio: r'$35.000', duracion: '2 h', score: 2 * 2.0 + 4.5 * 10),
    ],
    'Experiencias auténticas': [
      _ActividadCandidata(nombre: 'Metrocable y tour comunas',  emoji: '🚡', precio: r'$45.000', duracion: '4 h', score: 5 * 2.0 + 4.9 * 10),
      _ActividadCandidata(nombre: 'Escapada a Pueblo Cercano',  emoji: '🏘️', precio: r'$55.000', duracion: '6 h', score: 3 * 2.0 + 4.4 * 10),
    ],
    'Relax': [
      _ActividadCandidata(nombre: 'Atardecer Desde Terraza', emoji: '🌅', precio: r'$25.000', duracion: '2 h', score: 3 * 2.0 + 4.5 * 10),
      _ActividadCandidata(nombre: 'Picnic en Zona Verde',    emoji: '🧺', precio: r'$20.000', duracion: '3 h', score: 2 * 2.0 + 4.2 * 10),
    ],
    'Vida nocturna': [
      _ActividadCandidata(nombre: 'Clase de Salsa', emoji: '💃', precio: r'$50.000', duracion: '2 h', score: 4 * 2.0 + 4.6 * 10),
    ],
    'Cultura e historia': [
      _ActividadCandidata(nombre: 'Mercado de Diseño Local', emoji: '🎨', precio: r'$30.000', duracion: '2 h', score: 2 * 2.0 + 4.3 * 10),
    ],
  };

  final emojis = <String, String>{
    'Naturaleza y aventura': '🌿',
    'Gastronomía':           '🍴',
    'Experiencias auténticas': '🚡',
    'Relax':                 '🌅',
    'Vida nocturna':         '🌙',
    'Cultura e historia':    '🏛️',
  };

  return byCategory.entries.map((e) {
    final acts = e.value..sort((a, b) => b.score.compareTo(a.score));
    // Precio promedio
    final precios = acts.map((a) => _parsePrecioCOP(a.precio)).toList();
    final avgPrecio = precios.reduce((a, b) => a + b) / precios.length;
    // Duración promedio
    final durs = acts.map((a) => _parseDuracionH(a.duracion)).toList();
    final avgDur = durs.reduce((a, b) => a + b) / durs.length;

    return _CategoriaRanking(
      id: e.key.toLowerCase().replaceAll(' ', '_'),
      nombre: e.key,
      emoji: emojis[e.key] ?? '✨',
      precioPromedio: '\$${(avgPrecio / 1000).round()}.000 COP',
      duracionPromedio: '${avgDur.toStringAsFixed(1).replaceAll('.0', '')} h',
      actividades: acts,
    );
  }).toList()
    ..sort((a, b) {
      // Ordenar por score promedio de actividades
      final sa = a.actividades.map((x) => x.score).reduce((x, y) => x + y) / a.actividades.length;
      final sb = b.actividades.map((x) => x.score).reduce((x, y) => x + y) / b.actividades.length;
      return sb.compareTo(sa);
    });
}

List<_CategoriaRanking> _calcularCategoriasGenericas(String destinoKey) {
  final byCategory = <String, List<_ActividadCandidata>>{
    'Gastronomía': [
      _ActividadCandidata(nombre: 'Tour gastronómico local',   emoji: '🍴', precio: r'$55.000', duracion: '3 h', score: 4 * 2.0 + 4.6 * 10),
      _ActividadCandidata(nombre: 'Cena con vista panorámica', emoji: '🌆', precio: r'$80.000', duracion: '2 h', score: 3 * 2.0 + 4.8 * 10),
    ],
    'Naturaleza y aventura': [
      _ActividadCandidata(nombre: 'Senderismo y naturaleza',   emoji: '🥾', precio: r'$40.000', duracion: '4 h', score: 3 * 2.0 + 4.5 * 10),
      _ActividadCandidata(nombre: 'Excursión a sitio natural', emoji: '🌿', precio: r'$70.000', duracion: '5 h', score: 3 * 2.0 + 4.6 * 10),
    ],
    'Cultura e historia': [
      _ActividadCandidata(nombre: 'Recorrido cultural histórico', emoji: '🏛️', precio: r'$30.000', duracion: '3 h', score: 3 * 2.0 + 4.4 * 10),
      _ActividadCandidata(nombre: 'Mercado artesanal',           emoji: '🎨', precio: r'$25.000', duracion: '2 h', score: 2 * 2.0 + 4.3 * 10),
    ],
    'Vida nocturna': [
      _ActividadCandidata(nombre: 'Clase de baile local', emoji: '🎵', precio: r'$45.000', duracion: '2 h', score: 4 * 2.0 + 4.7 * 10),
    ],
    'Relax': [
      _ActividadCandidata(nombre: 'Tarde de relax y spa', emoji: '🧖', precio: r'$90.000', duracion: '3 h', score: 2 * 2.0 + 4.5 * 10),
    ],
  };
  final emojis = <String, String>{
    'Gastronomía':           '🍴',
    'Naturaleza y aventura': '🌿',
    'Cultura e historia':    '🏛️',
    'Vida nocturna':         '🌙',
    'Relax':                 '🌅',
  };
  return byCategory.entries.map((e) {
    final acts = e.value..sort((a, b) => b.score.compareTo(a.score));
    final precios = acts.map((a) => _parsePrecioCOP(a.precio)).toList();
    final avgPrecio = precios.reduce((a, b) => a + b) / precios.length;
    final durs = acts.map((a) => _parseDuracionH(a.duracion)).toList();
    final avgDur = durs.reduce((a, b) => a + b) / durs.length;
    return _CategoriaRanking(
      id: e.key.toLowerCase().replaceAll(' ', '_'),
      nombre: e.key,
      emoji: emojis[e.key] ?? '✨',
      precioPromedio: '\$${(avgPrecio / 1000).round()}.000 COP',
      duracionPromedio: '${avgDur.toStringAsFixed(1).replaceAll('.0', '')} h',
      actividades: acts,
    );
  }).toList()
    ..sort((a, b) {
      final sa = a.actividades.map((x) => x.score).reduce((x, y) => x + y) / a.actividades.length;
      final sb = b.actividades.map((x) => x.score).reduce((x, y) => x + y) / b.actividades.length;
      return sb.compareTo(sa);
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de parseo
// ─────────────────────────────────────────────────────────────────────────────
double _parsePrecioCOP(String precio) {
  final clean = precio.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(clean) ?? 50000;
}

double _parseDuracionH(String dur) {
  final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(dur);
  return double.tryParse(match?.group(1) ?? '2') ?? 2.0;
}

/// Selecciona las actividades finales a partir del ranking de categorías.
/// Para un viaje de [diasViaje] días se toman ~2 actividades por día.
/// Selecciona actividades finales a partir de las categorías rankeadas.
/// Meta: ~1-2 actividades principales por día (el itinerario agrega bloques logísticos).
List<ResumenActividad> _seleccionarActividadesFinales({
  required List<_CategoriaRanking> categoriasRankeadas,
  required int diasViaje,
}) {
  // Para demo: apuntamos a ~6 actividades principales en 4 días (~1-2 por día)
  // El itinerario agrega desayunos, traslados y planes de noche automáticamente.
  final totalActividades = (diasViaje + 2).clamp(4, 9);
  final result = <ResumenActividad>[];

  if (categoriasRankeadas.isEmpty) return result;

  // Ronda 1: prioridad a la 1ª actividad de cada categoría rankeada (las más votadas)
  for (final cat in categoriasRankeadas) {
    if (result.length >= totalActividades) break;
    if (cat.actividades.isNotEmpty) {
      final act = cat.actividades.first;
      if (!result.any((r) => r.nombre == act.nombre)) {
        result.add(ResumenActividad(
          nombre: act.nombre,
          categoria: act.emoji,
          precio: act.precio,
          duracion: act.duracion,
        ));
      }
    }
  }

  // Ronda 2: segundas actividades de cada categoría para completar el total
  for (final cat in categoriasRankeadas) {
    if (result.length >= totalActividades) break;
    if (cat.actividades.length > 1) {
      final act = cat.actividades[1];
      if (!result.any((r) => r.nombre == act.nombre)) {
        result.add(ResumenActividad(
          nombre: act.nombre,
          categoria: act.emoji,
          precio: act.precio,
          duracion: act.duracion,
        ));
      }
    }
  }

  // Ronda 3: terceras actividades si aún faltan
  for (final cat in categoriasRankeadas) {
    if (result.length >= totalActividades) break;
    if (cat.actividades.length > 2) {
      final act = cat.actividades[2];
      if (!result.any((r) => r.nombre == act.nombre)) {
        result.add(ResumenActividad(
          nombre: act.nombre,
          categoria: act.emoji,
          precio: act.precio,
          duracion: act.duracion,
        ));
      }
    }
  }

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────────────────────

class MesaChocoScreen extends StatefulWidget {
  final String? viajeId;
  final String? nombreViaje;
  final String destinoKey;
  final bool forzarConVotosActuales;

  const MesaChocoScreen({
    super.key,
    this.viajeId,
    this.nombreViaje,
    this.destinoKey = 'cartagena',
    this.forzarConVotosActuales = false,
  });

  @override
  State<MesaChocoScreen> createState() => _MesaChocoScreenState();
}

class _MesaChocoScreenState extends State<MesaChocoScreen> {
  late List<_CategoriaRanking> _pool;
  final List<_CategoriaRanking?> _ranking = List.filled(5, null);
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _pool = widget.destinoKey == 'medellin'
        ? _calcularCategoriasMedellin()
        : _calcularCategoriasGenericas(widget.destinoKey);
    _cargarBanner();
  }

  Future<void> _cargarBanner() async {
    try {
      final r = await AssetResolver.instance();
      final p = r.resolveDestinoImage(widget.destinoKey);
      if (mounted) setState(() => _bannerPath = p);
    } catch (_) {}
  }

  int get _rankingLleno => _ranking.where((r) => r != null).length;
  bool get _listoParaContinuar => _rankingLleno >= 1;

  void _agregar(_CategoriaRanking c) {
    final slot = _ranking.indexWhere((r) => r == null);
    if (slot == -1) return;
    setState(() => _ranking[slot] = c);
  }

  void _quitar(int i) => setState(() => _ranking[i] = null);

  void _moverArriba(int i) {
    if (i <= 0) return;
    setState(() {
      final tmp = _ranking[i - 1];
      _ranking[i - 1] = _ranking[i];
      _ranking[i] = tmp;
    });
  }

  void _moverAbajo(int i) {
    if (i >= 4) return;
    setState(() {
      final tmp = _ranking[i + 1];
      _ranking[i + 1] = _ranking[i];
      _ranking[i] = tmp;
    });
  }

  /// Coloca categoría en slot específico (drag desde pool o desde otro slot).
  /// Si la categoría ya está en otro slot, intercambia posiciones.
  void _colocarEnSlot(int slot, _CategoriaRanking c) {
    setState(() {
      final actualEnDestino = _ranking[slot];
      // ¿Venía de otro slot?
      final origen = _ranking.indexOf(c);
      if (origen != -1) {
        _ranking[origen] = actualEnDestino;
      }
      _ranking[slot] = c;
    });
  }

  void _confirmar() {
    final rankeadas = _ranking.whereType<_CategoriaRanking>().toList();
    const diasViaje = 4;
    final actividadesFinales = _seleccionarActividadesFinales(
      categoriasRankeadas: rankeadas,
      diasViaje: diasViaje,
    );

    // Transición breve: Choco procesando
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _ChocoProcessingScreen(
        onDone: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResumenActividadesScreen(
              viajeId: widget.viajeId,
              nombreViaje: widget.nombreViaje,
              destinoKey: widget.destinoKey,
              actividadesElegidas: actividadesFinales,
              diasViaje: diasViaje,
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Header compacto ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              bannerPath: _bannerPath,
              nombreViaje: widget.nombreViaje,
              destinoKey: widget.destinoKey,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),

          // ── Mensaje Choco (consenso grupal) ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ChocoIllustration(size: 38, borderRadius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ya vi lo que le gustó al grupo.',
                            style: AppFonts.label(13, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ahora ordena los tipos de plan para cerrar el consenso. Yo selecciono las actividades finales según esto.',
                            style: AppFonts.body(12.5, height: 1.35, color: AppColors.text.withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Ranking de categorías ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Prioridad del grupo', style: AppFonts.title(15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_rankingLleno/5',
                          style: AppFonts.label(11, weight: FontWeight.w700).copyWith(color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    5,
                    (i) => DragTarget<_CategoriaRanking>(
                      onWillAcceptWithDetails: (_) => true,
                      onAcceptWithDetails: (d) => _colocarEnSlot(i, d.data),
                      builder: (context, candidates, rejected) {
                        final dragOver = candidates.isNotEmpty;
                        final cat = _ranking[i];
                        Widget slot = _RankingSlot(
                          posicion: i + 1,
                          categoria: cat,
                          dragOver: dragOver,
                          onQuitar: () => _quitar(i),
                          onSubir: cat != null && i > 0 ? () => _moverArriba(i) : null,
                          onBajar: cat != null && i < 4 && _ranking[i + 1] != null ? () => _moverAbajo(i) : null,
                        );
                        // Si hay categoría, hacerlo arrastrable también para reordenar
                        if (cat != null) {
                          slot = LongPressDraggable<_CategoriaRanking>(
                            data: cat,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(width: 280, child: _RankingSlot(posicion: i + 1, categoria: cat, dragOver: false, onQuitar: () {})),
                            ),
                            childWhenDragging: Opacity(opacity: 0.35, child: slot),
                            child: slot,
                          );
                        }
                        return slot;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Pool de categorías ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipos de plan', style: AppFonts.title(15)),
                  const SizedBox(height: 2),
                  Text(
                    'Toca para agregar o mantén presionado y arrastra al ranking',
                    style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final c = _pool[i];
                  final enRanking = _ranking.contains(c);
                  final lleno = _rankingLleno >= 5;
                  final chip = _CategoriaChip(
                    categoria: c,
                    enRanking: enRanking,
                    disabled: lleno && !enRanking,
                    onTap: enRanking || lleno ? null : () => _agregar(c),
                  );
                  // Solo categorías que NO están en el ranking se pueden arrastrar al ranking
                  if (enRanking) return chip;
                  return LongPressDraggable<_CategoriaRanking>(
                    data: c,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(width: 170, height: 110, child: chip),
                    ),
                    childWhenDragging: Opacity(opacity: 0.4, child: chip),
                    child: chip,
                  );
                },
                childCount: _pool.length,
              ),
            ),
          ),

          // ── CTA final ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Column(
                children: [
                  if (!_listoParaContinuar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Elige al menos una categoría para cerrar el consenso.',
                        textAlign: TextAlign.center,
                        style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.60)),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _listoParaContinuar ? AppColors.primaryDark : AppColors.outlineSoft,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.outlineSoft,
                        disabledForegroundColor: AppColors.text.withValues(alpha: 0.40),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _listoParaContinuar ? _confirmar : null,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        'Cerrar consenso del grupo',
                        style: AppFonts.label(15, weight: FontWeight.w900).copyWith(color: Colors.white),
                      ),
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
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String? bannerPath;
  final String? nombreViaje;
  final String destinoKey;
  final VoidCallback onBack;

  const _Header({
    this.bannerPath,
    this.nombreViaje,
    required this.destinoKey,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 130 + topSafe,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bannerPath != null)
            Image.asset(
              normalizeFlutterAssetKey(bannerPath!),
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) => _FallbackBg(),
            )
          else
            _FallbackBg(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Positioned(
            top: topSafe + 6,
            left: 6,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_restaurant_rounded, size: 11, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Mesa de Choco',
                        style: AppFonts.label(10.5, weight: FontWeight.w700).copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombreViaje ?? 'Hora de priorizar',
                  style: AppFonts.display(20)
                      .copyWith(color: Colors.white, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _RankingSlot extends StatelessWidget {
  final int posicion;
  final _CategoriaRanking? categoria;
  final bool dragOver;
  final VoidCallback onQuitar;
  final VoidCallback? onSubir;
  final VoidCallback? onBajar;

  const _RankingSlot({
    required this.posicion,
    required this.categoria,
    this.dragOver = false,
    required this.onQuitar,
    this.onSubir,
    this.onBajar,
  });

  Color get _posColor {
    switch (posicion) {
      case 1: return const Color(0xFFF9A825);
      case 2: return const Color(0xFF90A4AE);
      case 3: return const Color(0xFFBF8D52);
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: dragOver
              ? AppColors.primary.withValues(alpha: 0.16)
              : categoria != null
                  ? AppColors.surfaceElevated
                  : AppColors.creamLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dragOver
                ? AppColors.primaryDark
                : categoria != null
                    ? _posColor.withValues(alpha: 0.50)
                    : AppColors.outlineSoft,
            width: dragOver ? 2 : (categoria != null ? 1.5 : 1),
          ),
          boxShadow: categoria != null
              ? [BoxShadow(color: _posColor.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _posColor.withValues(alpha: categoria != null ? 0.15 : 0.07),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$posicion',
                  style: AppFonts.label(12, weight: FontWeight.w900).copyWith(
                    color: categoria != null ? _posColor : AppColors.text.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: categoria != null
                  ? Row(
                      children: [
                        Text(categoria!.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                categoria!.nombre,
                                style: AppFonts.label(12.5, weight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${categoria!.cantidad} planes · ${categoria!.precioPromedio}',
                                style: AppFonts.body(11, color: AppColors.text.withValues(alpha: 0.58)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      dragOver ? 'Suelta aquí' : 'Vacío · arrastra una categoría',
                      style: AppFonts.body(
                        12.5,
                        color: dragOver ? AppColors.primaryDark : AppColors.text.withValues(alpha: 0.42),
                        weight: dragOver ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
            ),
            if (categoria != null) ...[
              // Flechas de reorden
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onSubir,
                    child: Icon(Icons.keyboard_arrow_up_rounded, size: 18,
                        color: onSubir != null ? AppColors.primaryDark.withValues(alpha: 0.65) : AppColors.outlineSoft),
                  ),
                  GestureDetector(
                    onTap: onBajar,
                    child: Icon(Icons.keyboard_arrow_down_rounded, size: 18,
                        color: onBajar != null ? AppColors.primaryDark.withValues(alpha: 0.65) : AppColors.outlineSoft),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onQuitar,
                child: Icon(Icons.close_rounded, size: 17, color: AppColors.text.withValues(alpha: 0.40)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  final _CategoriaRanking categoria;
  final bool enRanking;
  final bool disabled;
  final VoidCallback? onTap;

  const _CategoriaChip({
    required this.categoria,
    required this.enRanking,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.40 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: enRanking
                ? AppColors.primary.withValues(alpha: 0.11)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enRanking
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.outlineSoft,
              width: enRanking ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(categoria.emoji,
                      style: const TextStyle(fontSize: 22)),
                  if (enRanking)
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primary),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria.nombre,
                    style: AppFonts.label(12.5, weight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${categoria.cantidad} act. · ${categoria.duracionPromedio}',
                    style: AppFonts.body(11,
                        color: AppColors.text.withValues(alpha: 0.58)),
                  ),
                  Text(
                    categoria.precioPromedio,
                    style: AppFonts.body(11,
                        color: AppColors.text.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de procesamiento de Choco (transición breve 2-3s)
// ─────────────────────────────────────────────────────────────────────────────
class _ChocoProcessingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const _ChocoProcessingScreen({required this.onDone});

  @override
  State<_ChocoProcessingScreen> createState() => _ChocoProcessingScreenState();
}

class _ChocoProcessingScreenState extends State<_ChocoProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _step = 0;
  Timer? _timer;

  static const _pasos = [
    'Cruzando gustos del grupo...',
    'Ajustando a tiempos y presupuesto...',
    '¡Selección lista!',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _step = (_step + 1) % _pasos.length);
      if (_step == _pasos.length - 1) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) widget.onDone();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Choco con halo animado
            Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _ctrl,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.0),
                          AppColors.primary.withValues(alpha: 0.5),
                          AppColors.primaryDark,
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                ),
                const ChocoIllustration(size: 84, borderRadius: 42),
              ],
            ),
            const SizedBox(height: 28),
            Text('Choco está armando el plan', style: AppFonts.display(20)),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _pasos[_step],
                key: ValueKey(_step),
                style: AppFonts.body(15, color: AppColors.text.withValues(alpha: 0.72)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
