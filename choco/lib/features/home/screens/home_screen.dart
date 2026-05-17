import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/app/main_shell.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/asistente/services/choco_assistant_service.dart';
import 'package:choco/features/auth/widgets/auth_modal_sheet.dart';
import 'package:choco/features/flujo_exploracion/screens/espera_grupo_exploracion_screen.dart';
import 'package:choco/features/perfil/widgets/perfil_sheet.dart';
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/features/viajes/screens/crear_viaje_flujo_screen.dart';
import 'package:choco/features/viajes/screens/mesa_choco_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _cargarBanner();
  }

  Future<void> _cargarBanner() async {
    try {
      final r = await AssetResolver.instance();
      // Siempre usa el primer viaje activo (que debe ser el demo)
      final viajes = kViajesMockRicos.where((v) => v.estadoDisplay == 'Activo').toList();
      if (viajes.isEmpty) return;
      final viaje = viajes.first;
      final p = r.resolveDestinoImage(viaje.destinoKey);
      if (mounted) setState(() => _bannerPath = p);
    } catch (_) {}
  }

  List<GrupoViajeModel> get _viajesActivos =>
      kViajesMockRicos.where((v) => v.estadoDisplay == 'Activo').toList();

  void _irACrearViaje() {
    final session = UserSession();
    if (!session.isLoggedIn) {
      abrirAuthEnSheet(
        context,
        onSuccess: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CrearViajeFlujoScreen()),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CrearViajeFlujoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: UserSession(),
        builder: (context, _) {
          final viajesActivos = _viajesActivos;
          final hayViajes = viajesActivos.isNotEmpty;
          final session = UserSession();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  topSafe: topSafe,
                  nombre: session.nombreDisplay,
                  isLoggedIn: session.isLoggedIn,
                ),
              ),

              // ── Stats ─────────────────────────────────────────────────
              if (session.isLoggedIn && hayViajes)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, 0),
                    child: _StatsRow(viajes: viajesActivos),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Hero card ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: hayViajes
                      ? _ViajeHeroCard(
                          viaje: viajesActivos.first,
                          bannerPath: _bannerPath,
                        )
                      : _BienvenidaCard(
                          isLoggedIn: session.isLoggedIn,
                          onCta: _irACrearViaje,
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // ── Acceso rápido ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, 110),
                sliver: SliverToBoxAdapter(
                  child: _AccesoRapido(onCrearViaje: _irACrearViaje),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final double topSafe;
  final String nombre;
  final bool isLoggedIn;

  const _Header({
    required this.topSafe,
    required this.nombre,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, topSafe + 14, AppSpacing.md, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? 'Hola, $nombre' : 'Bienvenido',
                  style: AppFonts.display(22),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn ? 'Tu próxima aventura te espera' : 'Tu próxima aventura empieza aquí',
                  style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const PerfilAvatarButton(size: 42),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<GrupoViajeModel> viajes;

  const _StatsRow({required this.viajes});

  @override
  Widget build(BuildContext context) {
    final pendientes = viajes
        .where((v) =>
            v.faseActual == ViajeFaseProducto.gastosViaje ||
            v.faseActual == ViajeFaseProducto.esperaGrupoVotacion)
        .length;

    return Row(
      children: [
        _StatChip(
          icon: Icons.explore_rounded,
          label: '${viajes.length} viajes',
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.payments_rounded,
          label: pendientes > 0 ? '$pendientes pendientes' : 'Al día',
          color: pendientes > 0 ? AppColors.owe : AppColors.owed,
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.calendar_month_rounded,
          label: '1 itinerario',
          color: AppColors.accentMuted,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppFonts.label(11.5, weight: FontWeight.w700)
                    .copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIAJE HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ViajeHeroCard extends StatelessWidget {
  final GrupoViajeModel viaje;
  final String? bannerPath;

  const _ViajeHeroCard({required this.viaje, this.bannerPath});

  String _ctaLabel(ViajeFaseProducto fase) {
    switch (fase) {
      case ViajeFaseProducto.explorarActividades:
        return 'Explorar actividades';
      case ViajeFaseProducto.esperaGrupoVotacion:
        return 'Ver estado del grupo';
      case ViajeFaseProducto.mesaChoco:
        return 'Ir a la Mesa de Choco';
      default:
        return 'Continuar';
    }
  }

  void _onTap(BuildContext context) {
    // Navegar al swipe de actividades si la fase lo permite
    if (viaje.faseActual == ViajeFaseProducto.explorarActividades) {
      navegarExplorarActividades(
        context,
        destinoKey: viaje.destinoKey,
        viajeId: '${viaje.id}',
        nombreViaje: viaje.nombreViaje,
      );
    } else if (viaje.faseActual == ViajeFaseProducto.esperaGrupoVotacion) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => EsperaGrupoExploracionScreen(
          destinoKey: viaje.destinoKey,
          viajeId: '${viaje.id}',
          nombreViaje: viaje.nombreViaje,
          planesInteresantes: 3,
        ),
      ));
    } else if (viaje.faseActual == ViajeFaseProducto.mesaChoco) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => MesaChocoScreen(
          viajeId: '${viaje.id}',
          nombreViaje: viaje.nombreViaje,
          destinoKey: viaje.destinoKey,
        ),
      ));
    } else {
      // Cambiar a la pestaña de Viajes
      MainShell.maybeOf(context)?.cambiarTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctaLabel = _ctaLabel(viaje.faseActual);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: bannerPath != null
                    ? Image.asset(
                        bannerPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) =>
                            _HeroBg(nombre: viaje.destinoNombre),
                      )
                    : _HeroBg(nombre: viaje.destinoNombre),
              ),
              // Gradiente más profundo para legibilidad
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.25, 1.0],
                    ),
                  ),
                ),
              ),
              // Info abajo
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PhaseBadge(label: viaje.faseActual.etiquetaCorta),
                    const SizedBox(height: 6),
                    Text(
                      viaje.nombreViaje,
                      style: AppFonts.display(20).copyWith(
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${viaje.destinoNombre}  ·  ${viaje.participantes} personas',
                      style: AppFonts.body(12, color: Colors.white.withValues(alpha: 0.82)),
                    ),
                    const SizedBox(height: 12),
                    // CTA full-width abajo de los datos
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _onTap(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.primaryDark),
                                const SizedBox(width: 6),
                                Text(
                                  ctaLabel,
                                  style: AppFonts.label(13.5, weight: FontWeight.w900)
                                      .copyWith(color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBg extends StatelessWidget {
  final String nombre;

  const _HeroBg({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          nombre,
          style: AppFonts.display(32)
              .copyWith(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final String label;

  const _PhaseBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.label(10.5, weight: FontWeight.w700)
            .copyWith(color: Colors.white),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// BIENVENIDA CARD (sin viajes)
// ─────────────────────────────────────────────────────────────────────────────
class _BienvenidaCard extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onCta;

  const _BienvenidaCard({required this.isLoggedIn, required this.onCta});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            const Color(0xFF3A4C22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(8, 4, 12, 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight_takeoff_rounded, size: 13, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Nueva aventura',
                        style: AppFonts.label(11.5, weight: FontWeight.w700)
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Empieza tu primera\naventura en grupo',
                  style: AppFonts.display(24).copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isLoggedIn
                      ? 'Crea un viaje, invita a tu grupo y deja que Choco lo organice todo.'
                      : 'Inicia sesión o regístrate para guardar tus viajes y gastos.',
                  style: AppFonts.body(
                    13.5,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onCta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 18, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          isLoggedIn
                              ? 'Crear nueva aventura'
                              : 'Empezar ahora',
                          style: AppFonts.label(14, weight: FontWeight.w800)
                              .copyWith(color: AppColors.primaryDark),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// ACCESO RÁPIDO
// ─────────────────────────────────────────────────────────────────────────────
class _AccesoRapido extends StatelessWidget {
  final VoidCallback onCrearViaje;

  const _AccesoRapido({required this.onCrearViaje});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text('Qué hacer', style: AppFonts.title(14, weight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        _buildGrid(context),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    final tiles = [
      _Tile(
        icon: Icons.add_location_alt_rounded,
        titulo: 'Nueva aventura',
        sub: 'Crea un viaje en grupo',
        color: AppColors.primaryDark,
        onTap: onCrearViaje,
      ),
      _Tile(
        icon: Icons.swipe_rounded,
        titulo: 'Explorar planes',
        sub: 'Actividades y destinos',
        color: const Color(0xFF4E7C3A),
        onTap: () => navegarExplorarActividades(context, destinoKey: 'cartagena'),
      ),
      _Tile(
        icon: Icons.group_add_rounded,
        titulo: 'Unirme con código',
        sub: 'Entra al viaje de alguien',
        color: AppColors.accentMuted,
        onTap: () => _mostrarUnirseConCodigo(context),
      ),
      _Tile(
        icon: Icons.chat_bubble_outline_rounded,
        titulo: 'Hablar con Choco',
        sub: 'Preguntas y sugerencias',
        color: AppColors.accent,
        onTap: () {
          final shell = MainShell.maybeOf(context);
          if (shell != null) shell.abrirChoco();
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (_, i) => _TileTap(tile: tiles[i]),
    );
  }
}

class _Tile {
  final IconData icon;
  final String titulo;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.titulo,
    required this.sub,
    required this.color,
    required this.onTap,
  });
}

void _mostrarUnirseConCodigo(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.text.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Unirme con código', style: AppFonts.title(18)),
            const SizedBox(height: 6),
            Text(
              'Pide el código al organizador del viaje y escríbelo aquí.',
              style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.65), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'ej: CHOCO-ABC123',
                hintStyle: AppFonts.body(14, color: AppColors.text.withValues(alpha: 0.4)),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineSoft),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Funcionalidad próximamente', style: AppFonts.body(14)),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Text('Unirme', style: AppFonts.label(15, weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TileTap extends StatelessWidget {
  final _Tile tile;

  const _TileTap({required this.tile});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: tile.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: tile.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tile.color.withValues(alpha: 0.18)),
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tile.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tile.icon, size: 20, color: tile.color),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.titulo,
                      style: AppFonts.label(13.5, weight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tile.sub,
                      style: AppFonts.body(
                        11,
                        color: AppColors.text.withValues(alpha: 0.52),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
