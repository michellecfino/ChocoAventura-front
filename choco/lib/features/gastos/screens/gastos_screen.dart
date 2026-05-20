import 'dart:async';
import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/core/widgets/destino_visual.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:flutter/material.dart';

import '../models/gastos_models.dart';
import '../services/gastos_service.dart';
import '../widgets/registrar_gasto_sheet.dart';
import 'detalle_gastos_viaje_screen.dart';

class GastosScreen extends StatefulWidget {
  final GastosService gastosService;

  const GastosScreen({
    super.key,
    required this.gastosService,
  });

  @override
  GastosScreenState createState() => GastosScreenState();
}

class GastosScreenState extends State<GastosScreen> {
  late final GastosService _service = widget.gastosService;
  FiltroGastosChip _filtro = FiltroGastosChip.todos;
  late Future<List<ViajeFinancieroResumen>> _future;
  final Map<String, String> _bannerPorViajeId = {};
  Timer? _refreshTimer;

  static const _filtrosOrden = <(FiltroGastosChip, String)>[
    (FiltroGastosChip.todos, 'Todos'),
    (FiltroGastosChip.pendientes, 'Pendientes'),
    (FiltroGastosChip.saldados, 'Saldados'),
  ];

  void reload() {
    setState(() {
      _future = _cargar();
    });
  }

  @override
  void initState() {
    super.initState();
    _future = _cargar();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && UserSession().isLoggedIn) reload();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _precargarBannersDestino(List<ViajeFinancieroResumen> viajes) async {
    try {
      final r = await AssetResolver.instance();
      final m = <String, String>{};
      for (final v in viajes) {
        final dk = (v.destinoKey ?? 'cartagena').toLowerCase();
        m[v.idViaje] = r.resolveDestinoImage(dk);
      }
      if (mounted) setState(() {
        _bannerPorViajeId
          ..clear()
          ..addAll(m);
      });
    } catch (_) {}
  }

  Future<List<ViajeFinancieroResumen>> _cargar() async {
    final usuarioId = UserSession().user?.id;
    if (usuarioId == null) return <ViajeFinancieroResumen>[];
    final raw = await _service.fetchViajesPorUsuario(usuarioId);
    await _precargarBannersDestino(raw);
    return _ordenar(raw);
  }

  List<ViajeFinancieroResumen> _ordenar(List<ViajeFinancieroResumen> lista) {
    final copia = List<ViajeFinancieroResumen>.from(lista);
    int tier(ViajeFinancieroResumen v) {
      if (v.tuDebes > 0 && v.teDeben <= 0) return 0;
      if (v.tuDebes <= 0 && v.teDeben > 0) return 1;
      if (v.tuDebes > 0 && v.teDeben > 0) return 2;
      return 3;
    }

    copia.sort((a, b) {
      final c = tier(a).compareTo(tier(b));
      if (c != 0) return c;
      return a.nombreViaje.compareTo(b.nombreViaje);
    });
    return copia;
  }

  bool _coincideFiltro(ViajeFinancieroResumen v) {
    switch (_filtro) {
      case FiltroGastosChip.pendientes:
        return v.tuDebes > 0 || v.teDeben > 0;
      case FiltroGastosChip.saldados:
        return v.tuDebes <= 0 && v.teDeben <= 0;
      case FiltroGastosChip.todos:
        return true;
    }
  }

  void _refrescar() => reload();

  int _cuentaPendientes(List<ViajeFinancieroResumen> lista) {
    return lista.where((v) => v.tuDebes > 0 || v.teDeben > 0).length;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_gasto_voz',
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            onPressed: () => mostrarRegistrarGastoSheet(
              context,
              viajePrefijado: null,
              service: _service,
              alGuardar: _refrescar,
              initialTab: 1,
            ),
            child: const Icon(Icons.mic_rounded, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab_gasto_manual',
            onPressed: () => mostrarRegistrarGastoSheet(
              context,
              viajePrefijado: null,
              service: _service,
              alGuardar: _refrescar,
              initialTab: 0,
            ),
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 4,
            highlightElevation: 7,
            icon: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
            label: Text(
              'Gasto',
              style: AppFonts.label(13, weight: FontWeight.w800).copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => reload(),
        child: FutureBuilder<List<ViajeFinancieroResumen>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snap.hasError) {
              return Center(child: Text('Algo salió mal: ${snap.error}', style: AppFonts.body(14)));
            }
            final todos = snap.data ?? [];
            final filtrados = todos.where(_coincideFiltro).toList();
            final pend = _cuentaPendientes(todos);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroGastos(
                    topInset: topInset,
                    pendientesCount: pend,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _filtrosOrden.map((e) {
                        final chip = e.$1;
                        final label = e.$2;
                        final sel = _filtro == chip;
                        return ChoiceChip(
                          label: Text(label),
                          selected: sel,
                          onSelected: (_) => setState(() => _filtro = chip),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          selectedColor: AppColors.primary.withValues(alpha: 0.22),
                          backgroundColor: AppColors.creamLight.withValues(alpha: 0.9),
                          labelStyle: AppFonts.label(12, weight: sel ? FontWeight.w800 : FontWeight.w600).copyWith(
                            color: AppColors.text,
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: sel ? AppColors.primary.withValues(alpha: 0.5) : AppColors.outlineSoft,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (filtrados.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No hay viajes con este filtro.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 108),
                    sliver: SliverList.separated(
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final v = filtrados[i];
                        return _ViajeCardRica(
                          viaje: v,
                          index: i,
                          bannerAssetPath: _bannerPorViajeId[v.idViaje],
                          onVerMas: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => DetalleGastosViajeScreen(
                                  resumen: v,
                                  service: _service,
                                ),
                              ),
                            );
                            _refrescar();
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroGastos extends StatelessWidget {
  final double topInset;
  final int pendientesCount;

  const _HeroGastos({
    required this.topInset,
    required this.pendientesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, topInset + 14, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.creamLight,
            AppColors.background,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.text.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                    ),
                    child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gastos del viaje', style: AppFonts.display(19)),
                        const SizedBox(height: 5),
                        Text(
                          'Todo claro para que la aventura siga',
                          style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.82), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineSoft),
              boxShadow: [
                BoxShadow(color: AppColors.shadowWarm, blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: AppColors.primaryDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pendientesCount == 0
                        ? 'Sin balances pendientes'
                        : '$pendientesCount ${pendientesCount == 1 ? 'viaje' : 'viajes'} con cuentas por revisar',
                    style: AppFonts.body(12, weight: FontWeight.w600),
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

class _ViajeCardRica extends StatelessWidget {
  final ViajeFinancieroResumen viaje;
  final int index;
  final String? bannerAssetPath;
  final VoidCallback onVerMas;

  const _ViajeCardRica({
    required this.viaje,
    required this.index,
    this.bannerAssetPath,
    required this.onVerMas,
  });

  List<Widget> _tagsEstadoViaje() {
    final chips = <Widget>[];
    if (viaje.tuDebes <= 0 && viaje.teDeben <= 0) {
      chips.add(_miniChip('Saldado'));
    } else {
      if (viaje.tuDebes > 0) chips.add(_miniChip('Debes'));
      if (viaje.teDeben > 0) chips.add(_miniChip('Te deben'));
    }
    return chips;
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: AppFonts.label(10, weight: FontWeight.w800).copyWith(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pctPres =
        viaje.presupuesto > 0 ? ((viaje.hasGastado / viaje.presupuesto) * 100).clamp(0, 999).round() : null;
    final estadoTags = _tagsEstadoViaje();

    return Material(
      elevation: 3,
      shadowColor: AppColors.shadowWarm,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onVerMas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerAssetPath != null)
                    BackendImage(
                      source: bannerAssetPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => DestinoCoverDecorada(
                        titulo: viaje.nombreViaje,
                        height: 64,
                      ),
                    )
                  else
                    DestinoCoverDecorada(titulo: viaje.nombreViaje, height: 64),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    top: 8,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            viaje.nombreViaje,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.title(14.5).copyWith(
                              color: Colors.white,
                              height: 1.15,
                              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (var i = 0; i < estadoTags.length; i++) ...[
                              if (i > 0) const SizedBox(height: 4),
                              estadoTags[i],
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _metricBlock('Tú debes', formatoCop(viaje.tuDebes), AppColors.owe),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _metricBlock('Te deben', formatoCop(viaje.teDeben), AppColors.owed),
                      ),
                      _vDivider(),
                      Expanded(
                        child: _metricBlock('Has gastado', formatoCop(viaje.hasGastado), AppColors.primaryDark),
                      ),
                    ],
                  ),
                  if (pctPres != null && viaje.presupuesto > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Presupuesto usado',
                          style: AppFonts.label(11.5, weight: FontWeight.w800),
                        ),
                        Text(
                          '$pctPres%',
                          style: AppFonts.amount(13).copyWith(color: AppColors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: (viaje.hasGastado / viaje.presupuesto).clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: AppColors.creamLight,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onVerMas,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.shadowWarm,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Ver detalles', style: AppFonts.label(14, weight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: AppColors.text.withValues(alpha: 0.08),
    );
  }

  Widget _metricBlock(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppFonts.body(10.5, color: AppColors.text.withValues(alpha: 0.72)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppFonts.amount(12).copyWith(color: valueColor),
        ),
      ],
    );
  }
}
