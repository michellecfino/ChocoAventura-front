import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/core/assets/known_bundled_asset_paths.dart';
import 'package:choco/features/flujo_exploracion/screens/espera_grupo_exploracion_screen.dart';
import 'package:choco/features/actividades/models/actividad_exploracion.dart';
import 'package:choco/features/actividades/services/actividades_catalogo_local.dart';
import 'package:choco/features/actividades/services/exploracion_actividades_memoria.dart';
import 'package:choco/features/gastos/models/gastos_models.dart';
import 'package:flutter/material.dart';

/// Argumentos para [ExplorarActividadesSwipeScreen] vía [Navigator.pushNamed].
class ExplorarActividadesArgs {
  final String destinoKey;
  final String? viajeId;
  final List<String>? preferenciasTags;
  final String? nombreViaje;

  const ExplorarActividadesArgs({
    required this.destinoKey,
    this.viajeId,
    this.preferenciasTags,
    this.nombreViaje,
  });
}

class ExplorarActividadesSwipeScreen extends StatefulWidget {
  final String destinoKey;
  final String? viajeId;
  final List<String>? preferenciasTags;
  final String? nombreViaje;

  const ExplorarActividadesSwipeScreen({
    super.key,
    required this.destinoKey,
    this.viajeId,
    this.preferenciasTags,
    this.nombreViaje,
  });

  @override
  State<ExplorarActividadesSwipeScreen> createState() => _ExplorarActividadesSwipeScreenState();
}

class _ExplorarActividadesSwipeScreenState extends State<ExplorarActividadesSwipeScreen> {
  late Future<_DeckCarga> _carga;
  _DeckCarga? _actual;
  int _indice = 0;
  int _chocovotos = 0;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _carga = _cargar();
  }

  Future<_DeckCarga> _cargar() async {
    var key = widget.destinoKey.toLowerCase().trim();
    if (!kDestinosAppKeys.contains(key)) {
      key = 'cartagena';
    }
    try {
      final resolver = await AssetResolver.instance();
      var paths = resolver.listarImagenesActividadCarpeta(key)..sort();
      if (paths.isEmpty) {
        key = 'cartagena';
        paths = resolver.listarImagenesActividadCarpeta(key)..sort();
      }
      final todas = construirActividadesDesdeAssets(destinoKey: key, rutasImagenesOrdenadas: paths);
      final deck = mezclarDeckActividades(
        todas: todas,
        interesesUsuario: widget.preferenciasTags,
        limiteInicial: todas.length > 48 ? 48 : todas.length,
      );
      return _DeckCarga(destinoKey: key, todas: todas, deck: deck);
    } catch (e, st) {
      debugPrint('Explorar actividades: $e\n$st');
      var paths = knownActividadImagePathsForKey(key)..sort();
      if (paths.isEmpty) {
        key = 'cartagena';
        paths = knownActividadImagePathsForKey(key)..sort();
      }
      final todas = construirActividadesDesdeAssets(destinoKey: key, rutasImagenesOrdenadas: paths);
      final deck = mezclarDeckActividades(
        todas: todas,
        interesesUsuario: widget.preferenciasTags,
        limiteInicial: todas.length > 48 ? 48 : todas.length,
      );
      return _DeckCarga(destinoKey: key, todas: todas, deck: deck);
    }
  }

  String get _claveMem =>
      ExploracionActividadesMemoria.claveSesion(viajeId: widget.viajeId, destinoKey: _actual?.destinoKey ?? widget.destinoKey);

  ActividadExploracion? get _top {
    final d = _actual;
    if (d == null || _indice >= d.deck.length) return null;
    return d.deck[_indice];
  }

  void _siguiente() {
    setState(() {
      _drag = Offset.zero;
      _indice++;
    });
  }

  void _meInteresa() {
    final a = _top;
    if (a == null) return;
    ExploracionActividadesMemoria.registrarInteres(_claveMem, a.id);
    setState(() {
      _chocovotos++;
      _drag = Offset.zero;
      _indice++;
    });
  }

  void _paso() {
    final a = _top;
    if (a == null) return;
    ExploracionActividadesMemoria.registrarPaso(_claveMem, a.id);
    _siguiente();
  }

  void _seguirExplorando() {
    final d = _actual;
    if (d == null) return;
    final usados = {...ExploracionActividadesMemoria.meInteresaIds(_claveMem), ...ExploracionActividadesMemoria.pasoIds(_claveMem)};
    final restantes = d.todas.where((a) => !usados.contains(a.id)).toList();
    if (restantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya viste todas las ideas de Choco por ahora.', style: AppFonts.body(14))),
      );
      return;
    }
    final nuevo = mezclarDeckActividades(
      todas: restantes,
      interesesUsuario: widget.preferenciasTags,
      limiteInicial: restantes.length.clamp(10, 36),
    );
    setState(() {
      _actual = _DeckCarga(destinoKey: d.destinoKey, todas: d.todas, deck: nuevo);
      _indice = 0;
      _drag = Offset.zero;
    });
  }

  void _irAEsperaGrupo() {
    final d = _actual;
    if (d == null) return;
    final n = ExploracionActividadesMemoria.meInteresaIds(_claveMem).length;
    // El viaje demo (id=7) tiene 4/5 personas listas; el usuario es la última.
    final esUltimo = widget.viajeId == '7';
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EsperaGrupoExploracionScreen(
          destinoKey: d.destinoKey,
          viajeId: widget.viajeId,
          nombreViaje: widget.nombreViaje,
          planesInteresantes: n,
          esUltimoEnVotar: esUltimo,
        ),
      ),
    );
  }

  void _abrirDetalle(ActividadExploracion a) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetalleActividadSheet(actividad: a),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Explorar actividades', style: AppFonts.title(17)),
            if (widget.nombreViaje != null && widget.nombreViaje!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                widget.nombreViaje!.trim(),
                style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.72)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
      body: FutureBuilder<_DeckCarga>(
        future: _carga,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No pudimos cargar el mazo en este momento.',
                      textAlign: TextAlign.center,
                      style: AppFonts.body(14),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() {
                        _carga = _cargar();
                      }),
                      child: Text('Reintentar', style: AppFonts.label(14, weight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _actual ??= snap.data!;
          final d = _actual!;
          if (d.todas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No encontramos imágenes de actividades para este destino en la app. '
                  'Revisa que existan archivos en la carpeta del destino.',
                  textAlign: TextAlign.center,
                  style: AppFonts.body(14, height: 1.45),
                ),
              ),
            );
          }
          final top = _top;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombreLegibleDestino(d.destinoKey),
                            style: AppFonts.label(13, weight: FontWeight.w800),
                          ),
                        ),
                        if (_chocovotos > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded, size: 12, color: AppColors.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  '$_chocovotos',
                                  style: AppFonts.label(11.5, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: d.deck.isEmpty ? 1 : (_indice / d.deck.length).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.outlineSoft,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      top == null
                          ? '¡Exploraste todo!'
                          : top.nombre.length > 28
                              ? '${top.nombre.substring(0, 26)}…'
                              : top.nombre,
                      style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.65)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: top == null
                    ? _FinLista(
                        onSeguir: _seguirExplorando,
                        onTerminar: _irAEsperaGrupo,
                        meInteresa: ExploracionActividadesMemoria.meInteresaIds(_claveMem).length,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (e) => setState(() => _drag += e.delta),
                                onPanEnd: (_) {
                                  const thrX = 90.0;
                                  const thrY = 70.0;
                                  if (_drag.dx > thrX) {
                                    _meInteresa();
                                  } else if (_drag.dx < -thrX) {
                                    _paso();
                                  } else if (_drag.dy > thrY) {
                                    _abrirDetalle(top);
                                    setState(() => _drag = Offset.zero);
                                  } else {
                                    setState(() => _drag = Offset.zero);
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (d.deck.length > _indice + 1)
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 18, left: 10, right: 10),
                                          child: Transform.scale(
                                            scale: 0.94,
                                            child: _CardPreview(actividad: d.deck[_indice + 1]),
                                          ),
                                        ),
                                      ),
                                    Transform.translate(
                                      offset: _drag,
                                      child: Transform.rotate(
                                        angle: _drag.dx * 0.002,
                                        child: _ActividadSwipeCard(
                                          actividad: top,
                                          onVerMas: () => _abrirDetalle(top),
                                          overlayLike: _drag.dx > 26,
                                          overlayNope: _drag.dx < -26,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swipe_left_rounded, size: 14, color: AppColors.text.withValues(alpha: 0.45)),
                                const SizedBox(width: 4),
                                Text(
                                  'Paso',
                                  style: AppFonts.body(11, color: AppColors.text.withValues(alpha: 0.50)),
                                ),
                                Text(
                                  '  ·  desliza  ·  ',
                                  style: AppFonts.body(11, color: AppColors.text.withValues(alpha: 0.35)),
                                ),
                                Text(
                                  'Me interesa',
                                  style: AppFonts.body(11, color: AppColors.text.withValues(alpha: 0.50)),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.swipe_right_rounded, size: 14, color: AppColors.text.withValues(alpha: 0.45)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      side: BorderSide(color: AppColors.text.withValues(alpha: 0.22)),
                                    ),
                                    onPressed: _paso,
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    label: Text('Paso', style: AppFonts.label(14, weight: FontWeight.w800)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primaryDark,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onPressed: _meInteresa,
                                    icon: const Icon(Icons.favorite_rounded, size: 20),
                                    label: Text('Me interesa', style: AppFonts.label(14, weight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
                                  foregroundColor: AppColors.primaryDark,
                                ),
                                onPressed: _irAEsperaGrupo,
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(
                                  widget.viajeId == '7'
                                      ? 'Listo, ver estado del grupo'
                                      : 'Terminar exploración por ahora',
                                  style: AppFonts.label(13, weight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _capitalizarEtiqueta(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return raw;
  const map = {
    'bogota': 'Bogotá',
    'medellin': 'Medellín',
    'cartagena': 'Cartagena',
    'amazonas': 'Amazonas',
    'cali': 'Cali',
  };
  return t.split(RegExp(r'\s+')).map((w) {
    final lower = w.toLowerCase();
    if (map.containsKey(lower)) return map[lower]!;
    if (w.isEmpty) return w;
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

String _etiquetaAfinidad(ActividadExploracion a) {
  if (a.rating >= 4.7 && a.popularidad >= 82) return 'Muy recomendado';
  if (a.popularidad >= 78) return 'Favorito del destino';
  if (a.popularidad >= 70) return 'Popular';
  if (a.popularidad >= 62) return 'Alta afinidad';
  return 'Recomendado por Choco';
}

class _DeckCarga {
  final String destinoKey;
  final List<ActividadExploracion> todas;
  final List<ActividadExploracion> deck;

  _DeckCarga({required this.destinoKey, required this.todas, required this.deck});
}

class _FinLista extends StatelessWidget {
  final VoidCallback onSeguir;
  final VoidCallback onTerminar;
  final int meInteresa;

  const _FinLista({required this.onSeguir, required this.onTerminar, required this.meInteresa});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.85)),
          const SizedBox(height: 14),
          Text('¡Buen ojo!', textAlign: TextAlign.center, style: AppFonts.title(20)),
          const SizedBox(height: 8),
          Text(
            'Te interesaron $meInteresa planes. Más adelante podrás alinear esto con tu grupo en la mesa de Choco.',
            textAlign: TextAlign.center,
            style: AppFonts.body(14, height: 1.45),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onSeguir,
            child: Text('Seguir explorando', style: AppFonts.label(14, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onTerminar,
            child: Text('Terminar exploración', style: AppFonts.label(14, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final ActividadExploracion actividad;

  const _CardPreview({required this.actividad});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Image.asset(
        normalizeFlutterAssetKey(actividad.imagenAssetPath),
        fit: BoxFit.cover,
        errorBuilder: (context, e, s) => Container(color: AppColors.surfaceMuted),
      ),
    );
  }
}

class _ActividadSwipeCard extends StatelessWidget {
  final ActividadExploracion actividad;
  final VoidCallback onVerMas;
  final bool overlayLike;
  final bool overlayNope;

  const _ActividadSwipeCard({
    required this.actividad,
    required this.onVerMas,
    required this.overlayLike,
    required this.overlayNope,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
              Image.asset(
                normalizeFlutterAssetKey(actividad.imagenAssetPath),
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined, color: AppColors.text.withValues(alpha: 0.35)),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              if (overlayLike)
                Positioned(
                  top: 26,
                  left: 22,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.greenAccent.shade100, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ME INTERESA',
                        style: AppFonts.label(18, weight: FontWeight.w900).copyWith(color: Colors.greenAccent.shade100),
                      ),
                    ),
                  ),
                ),
              if (overlayNope)
                Positioned(
                  top: 26,
                  right: 22,
                  child: Transform.rotate(
                    angle: 0.18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent.shade100, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PASO',
                        style: AppFonts.label(18, weight: FontWeight.w900).copyWith(color: Colors.redAccent.shade100),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalizarEtiqueta(actividad.categoria),
                      style: AppFonts.label(12, weight: FontWeight.w800).copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actividad.nombre,
                      style: AppFonts.display(22).copyWith(color: Colors.white, height: 1.05),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      actividad.destinoNombre,
                      style: AppFonts.body(13, color: Colors.white.withValues(alpha: 0.88)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: actividad.tags.take(4).map((t) {
                        return Chip(
                          label: Text(_capitalizarEtiqueta(t), style: AppFonts.label(11, weight: FontWeight.w700)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.payments_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${formatoCop(actividad.precioEstimado)} COP',
                          style: AppFonts.label(13.5, weight: FontWeight.w800).copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.9), size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            actividad.duracion,
                            style: AppFonts.body(12.5, color: Colors.white.withValues(alpha: 0.9)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber.shade200, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${actividad.rating.toStringAsFixed(1)} · ${_etiquetaAfinidad(actividad)}',
                          style: AppFonts.body(12.5, color: Colors.white.withValues(alpha: 0.92)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onVerMas,
                      icon: const Icon(Icons.expand_more_rounded, color: Colors.white),
                      label: Text(
                        'Ver más',
                        style: AppFonts.label(13.5, weight: FontWeight.w800).copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _DetalleActividadSheet extends StatelessWidget {
  final ActividadExploracion actividad;

  const _DetalleActividadSheet({required this.actividad});

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(24));
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: radius,
            boxShadow: [BoxShadow(color: AppColors.shadowWarm, blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: CustomScrollView(
              controller: scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      SizedBox(
                        height: 200,
                        child: Image.asset(
                          normalizeFlutterAssetKey(actividad.imagenAssetPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(color: AppColors.surfaceMuted),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(actividad.nombre, style: AppFonts.display(22)),
                            const SizedBox(height: 6),
                            Text('${actividad.destinoNombre} · ${actividad.categoria}', style: AppFonts.body(13.5, height: 1.35)),
                            const SizedBox(height: 14),
                            Text('Sobre esta actividad', style: AppFonts.label(13, weight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(actividad.descripcionLarga, style: AppFonts.body(14, height: 1.45)),
                            const SizedBox(height: 16),
                            _bloque('Ubicación', actividad.ubicacionTexto),
                            _bloque('Horario recomendado', actividad.horarioSugerido),
                            _bloque('Precio estimado por persona', '${formatoCop(actividad.precioEstimado)} COP'),
                            _bloque('Qué puede incluir', actividad.incluye.map((e) => '· $e').join('\n')),
                            _bloque('Recomendaciones de Choco', actividad.recomendacionesChoco),
                            _bloque('Intensidad', '${actividad.intensidad}/5'),
                            _bloque('Ideal para', actividad.aptoPara.join(', ')),
                            _bloque('Accesibilidad', actividad.accesibilidadNota),
                            _bloque('Etiquetas', actividad.tags.join(', ')),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.outlineSoft),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.map_outlined, color: AppColors.primaryDark),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Mapa próximamente: Choco está preparando la ruta para que veas el punto en el mapa sin complicaciones.',
                                      style: AppFonts.body(13, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bloque(String titulo, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppFonts.label(12.5, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(texto, style: AppFonts.body(14, height: 1.4)),
        ],
      ),
    );
  }
}
