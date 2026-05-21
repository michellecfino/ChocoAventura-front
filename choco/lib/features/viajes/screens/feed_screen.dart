import 'dart:async';
import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/app/main_shell.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/asistente/services/choco_assistant_service.dart';
import 'package:choco/features/actividades/screens/explorar_actividades_swipe_screen.dart';
import 'package:choco/features/flujo_exploracion/screens/espera_grupo_exploracion_screen.dart';
import 'package:choco/features/gastos/models/gastos_models.dart';
import 'package:choco/features/gastos/screens/detalle_gastos_viaje_screen.dart';
import 'package:choco/features/gastos/services/gastos_service.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/features/itinerario/screens/ItinerarioScreen.dart';
import 'package:choco/features/viajes/screens/crear_viaje_flujo_screen.dart';
import 'package:choco/features/viajes/screens/mesa_choco_screen.dart';
import 'package:choco/features/viajes/screens/unirse_viaje_codigo_screen.dart';
import 'package:choco/features/viajes/services/viajes_service.dart';
import 'package:choco/features/viajes/widgets/viaje_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final Map<int, String> _bannerPorId = {};
  bool _cargandoBanners = true;
  List<GrupoViajeModel> _viajes = <GrupoViajeModel>[];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    UserSession().addListener(_cargarViajesUsuario);
    _cargarViajesUsuario();
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && UserSession().isLoggedIn) {
        _cargarViajesUsuario(mostrarCargando: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    UserSession().removeListener(_cargarViajesUsuario);
    super.dispose();
  }

  Future<void> _cargarViajesUsuario({bool mostrarCargando = true}) async {
    final user = UserSession().user;
    if (user?.id == null) {
      if (mounted) {
        setState(() {
          _viajes = <GrupoViajeModel>[];
          _bannerPorId.clear();
          _cargandoBanners = false;
        });
      }
      return;
    }
    if (mounted && mostrarCargando) setState(() => _cargandoBanners = true);
    try {
      final viajes = await const ViajesService().cargarViajesUsuario(user!.id!);
      final r = await AssetResolver.instance();
      final m = <int, String>{};
      for (final v in viajes) {
        if (v.id != null) m[v.id!] = r.resolveDestinoImage(v.destinoKey);
      }
      if (mounted) {
        setState(() {
          _viajes = viajes;
          _bannerPorId
            ..clear()
            ..addAll(m);
          _cargandoBanners = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _viajes = <GrupoViajeModel>[];
          _bannerPorId.clear();
          _cargandoBanners = false;
        });
      }
    }
  }

  Future<void> _ctaViaje(BuildContext context, GrupoViajeModel v) async {
    if (v.faseActual == ViajeFaseProducto.explorarActividades) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExplorarActividadesSwipeScreen(
            destinoKey: v.destinoKey,
            viajeId: '${v.id}',
            nombreViaje: v.nombreViaje,
          ),
        ),
      );
      await _cargarViajesUsuario();
      return;
    }
    if (v.faseActual == ViajeFaseProducto.esperaGrupoVotacion) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EsperaGrupoExploracionScreen(
            destinoKey: v.destinoKey,
            viajeId: '${v.id}',
            nombreViaje: v.nombreViaje,
            planesInteresantes: 3,
          ),
        ),
      );
      await _cargarViajesUsuario();
      return;
    }
    if (v.faseActual == ViajeFaseProducto.gastosViaje) {
      await _abrirGastosDelViaje(context, v);
      return;
    }
    if (v.faseActual == ViajeFaseProducto.mesaChoco) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MesaChocoScreen(
            viajeId: '${v.id}',
            nombreViaje: v.nombreViaje,
            destinoKey: v.destinoKey,
          ),
        ),
      );
      await _cargarViajesUsuario();
      return;
    }
    if (v.faseActual == ViajeFaseProducto.priorizacionCategorias) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MesaChocoScreen(
            viajeId: '${v.id}',
            destinoKey: v.destinoKey,
            nombreViaje: v.nombreViaje,
          ),
        ),
      );
      await _cargarViajesUsuario();
      return;
    }
    if (v.faseActual == ViajeFaseProducto.itinerarioGenerado ||
        v.faseActual == ViajeFaseProducto.ajustesItinerario ||
        v.faseActual == ViajeFaseProducto.viajeActivo) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ItinerarioScreen(
            itinerarioId: v.itinerarioId ?? v.id ?? 1,
            destinoKey: v.destinoKey,
          ),
        ),
      );
      await _cargarViajesUsuario();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CrearViajeFlujoScreen(viajeBorrador: v)),
    );
    await _cargarViajesUsuario();
  }

  Future<void> _abrirGastosDelViaje(BuildContext context, GrupoViajeModel v) async {
    final id = '${v.id ?? ''}';
    if (id.isEmpty) return;
    final shell = MainShell.maybeOf(context);
    final service = shell?.gastosService ?? GastosService();
    try {
      final usuarioId = UserSession().user?.id;
      if (usuarioId == null) return;
      final lista = await service.fetchViajesPorUsuario(usuarioId);
      ViajeFinancieroResumen? resumen;
      for (final e in lista) {
        if (e.idViaje == id) {
          resumen = e;
          break;
        }
      }
      resumen ??= lista.isNotEmpty ? lista.first : null;
      if (!context.mounted) return;
      final viajeFin = resumen;
      if (viajeFin == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No encontré gastos para este viaje.', style: AppFonts.body(14))),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DetalleGastosViajeScreen(
            resumen: viajeFin,
            service: service,
          ),
        ),
      );
      shell?.recargarPestanaGastos();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No pude abrir los gastos. Inténtalo de nuevo.', style: AppFonts.body(14))),
        );
      }
    }
  }

  void _detalle(BuildContext context, GrupoViajeModel v) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(ctx).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(v.nombreViaje, style: AppFonts.title(18)),
              const SizedBox(height: 6),
              Text(v.ciudadDepartamento, style: AppFonts.body(14)),
              const SizedBox(height: 6),
              Text('Fase: ${v.faseActual.etiquetaCorta}', style: AppFonts.label(12.5, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${v.participantes} personas en el grupo', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.78))),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.creamLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código del viaje', style: AppFonts.label(12, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: SelectableText(v.codigoInvitacion, style: AppFonts.title(16))),
                        TextButton.icon(
                          onPressed: () async {
                            try {
                              await Clipboard.setData(ClipboardData(text: v.codigoInvitacion));
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Código copiado', style: AppFonts.body(14))),
                              );
                            } catch (_) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('No se pudo copiar el código.', style: AppFonts.body(14))),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: Text('Copiar', style: AppFonts.label(13, weight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Enlace de invitación', style: AppFonts.label(12, weight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    SelectableText(v.linkInvitacion, style: AppFonts.body(12.5, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _ctaViaje(context, v);
                },
                child: Text(v.faseActual.ctaPrincipal, style: AppFonts.label(14, weight: FontWeight.w800)),
              ),
              if (v.puedeExplorar || v.faseActual == ViajeFaseProducto.explorarActividades) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    navegarExplorarActividades(context, destinoKey: v.destinoKey, viajeId: '${v.id}', nombreViaje: v.nombreViaje);
                  },
                  child: Text('Explorar actividades', style: AppFonts.label(13.5, weight: FontWeight.w800)),
                ),
              ],
              if (v.puedePriorizar || v.faseActual == ViajeFaseProducto.priorizacionCategorias) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MesaChocoScreen(
                          viajeId: '${v.id}',
                          destinoKey: v.destinoKey,
                          nombreViaje: v.nombreViaje,
                        ),
                      ),
                    );
                    if (mounted) _cargarViajesUsuario();
                  },
                  child: Text('Ir a la Mesa de Choco', style: AppFonts.label(13.5, weight: FontWeight.w800)),
                ),
              ],
              if (v.faseActual == ViajeFaseProducto.mesaChoco) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MesaChocoScreen(
                          viajeId: '${v.id}',
                          nombreViaje: v.nombreViaje,
                          destinoKey: v.destinoKey,
                        ),
                      ),
                    );
                  },
                  child: Text('Mesa de Choco', style: AppFonts.label(13.5, weight: FontWeight.w800)),
                ),
              ],
              if (v.faseActual == ViajeFaseProducto.itinerarioGenerado ||
                  v.faseActual == ViajeFaseProducto.ajustesItinerario ||
                  v.faseActual == ViajeFaseProducto.viajeActivo) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ItinerarioScreen(itinerarioId: v.itinerarioId ?? v.id ?? 1, destinoKey: v.destinoKey),
                      ),
                    );
                  },
                  child: Text('Itinerario', style: AppFonts.label(13.5, weight: FontWeight.w800)),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Los gastos del viaje están en la pestaña inferior «Gastos».',
                style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;
    final viajes = UserSession().isLoggedIn ? _viajes : <GrupoViajeModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, topSafe + 14, AppSpacing.md, AppSpacing.sm),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Tus aventuras',
                      textAlign: TextAlign.center,
                      style: AppFonts.display(22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Retoma el ritmo donde lo dejaste',
                      textAlign: TextAlign.center,
                      style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.78)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const CrearViajeFlujoScreen()),
                            );
                            if (mounted) _cargarViajesUsuario();
                          },
                          icon: const Icon(Icons.add_road_rounded, size: 20),
                          label: Text('Nueva aventura', style: AppFonts.label(13, weight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const UnirseViajeCodigoScreen()),
                            );
                            if (mounted) _cargarViajesUsuario();
                          },
                          icon: const Icon(Icons.key_rounded, size: 19),
                          label: Text('Unirse', style: AppFonts.label(13, weight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_cargandoBanners)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
            ),
          if (!_cargandoBanners && viajes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineSoft),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Icon(Icons.explore_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.85)),
                        const SizedBox(height: 12),
                        Text('Todavía no tienes viajes', textAlign: TextAlign.center, style: AppFonts.title(17)),
                        const SizedBox(height: 8),
                        Text('Crea una aventura o únete a un grupo para ver aquí solo tus viajes.', textAlign: TextAlign.center, style: AppFonts.body(14, height: 1.45, color: AppColors.text.withValues(alpha: 0.78))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final v = viajes[i];
                  return ViajeCard(
                    viaje: v,
                    bannerAssetPath: v.id != null ? _bannerPorId[v.id!] : null,
                    onVerDetalle: () => _detalle(context, v),
                    onCtaPrincipal: () => _ctaViaje(context, v),
                  );
                },
                childCount: viajes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
