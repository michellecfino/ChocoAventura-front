import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/widgets/mobile_app_frame.dart';
import 'package:choco/features/gastos/screens/gastos_screen.dart';
import 'package:choco/features/gastos/services/gastos_service.dart';
import 'package:choco/features/gastos/widgets/choco_assistant_sheet.dart';
import 'package:choco/core/widgets/choco_nav_logo.dart';
import 'package:choco/features/home/screens/home_screen.dart';
import 'package:choco/features/itinerario/screens/itinerario_hub_screen.dart';
import 'package:choco/features/viajes/screens/feed_screen.dart';
import 'package:flutter/material.dart';

/// Navegación: Inicio | Viajes | **Choco** | Itinerario | Gastos
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Para pantallas hijas (p. ej. Viajes) que necesitan el mismo [GastosService] que la pestaña Gastos.
  static MainShellState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  final GastosService _gastosService = GastosService();
  final GlobalKey<GastosScreenState> _gastosKey = GlobalKey<GastosScreenState>();

  GastosService get gastosService => _gastosService;

  void recargarPestanaGastos() => _gastosKey.currentState?.reload();

  /// Cambia a la pestaña indicada: 0 Inicio, 1 Viajes, 2 Itinerario, 3 Gastos.
  void cambiarTab(int pageIndex) {
    if (pageIndex >= 0 && pageIndex <= 3) {
      setState(() => _pageIndex = pageIndex);
    }
  }

  /// 0 Inicio, 1 Viajes, 2 Itinerario, 3 Gastos
  int _pageIndex = 0;

  late AnimationController _chocoPulse;
  late Animation<double> _chocoPulseScale;

  @override
  void initState() {
    super.initState();
    _chocoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _chocoPulseScale = Tween<double>(begin: 1.0, end: 1.028).animate(
      CurvedAnimation(parent: _chocoPulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _chocoPulse.dispose();
    super.dispose();
  }

  void _openChocoAsistente() {
    mostrarAsistenteGlobalChoco(
      context,
      service: _gastosService,
      onActualizado: () {
        _gastosKey.currentState?.reload();
        setState(() {});
      },
    );
  }

  void _onNavTap(int slot) {
    if (slot == 2) {
      _openChocoAsistente();
      return;
    }
    final page = slot < 2 ? slot : slot - 1;
    setState(() => _pageIndex = page);
  }

  int _highlightSlot() {
    return _pageIndex < 2 ? _pageIndex : _pageIndex + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _pageIndex,
        children: [
          const HomeScreen(),
          const FeedScreen(),
          const ItinerarioHubScreen(),
          GastosScreen(
            key: _gastosKey,
            gastosService: _gastosService,
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > MobileAppFrame.maxWidth + 32;
                final bar = _FloatingDock(
                  highlightSlot: _highlightSlot(),
                  chocoScale: _chocoPulseScale,
                  onTap: _onNavTap,
                  onChocoTap: _openChocoAsistente,
                );
                if (!wide) return bar;
                return Center(
                  child: SizedBox(
                    width: MobileAppFrame.maxWidth,
                    child: bar,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  final int highlightSlot;
  final Animation<double> chocoScale;
  final void Function(int slot) onTap;
  final VoidCallback onChocoTap;

  const _FloatingDock({
    required this.highlightSlot,
    required this.chocoScale,
    required this.onTap,
    required this.onChocoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.creamLight.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DockItem(
            slot: 0,
            icon: Icons.home_rounded,
            label: 'Inicio',
            selected: highlightSlot == 0,
            onTap: () => onTap(0),
          ),
          _DockItem(
            slot: 1,
            icon: Icons.explore_rounded,
            label: 'Viajes',
            selected: highlightSlot == 1,
            onTap: () => onTap(1),
          ),
          _ChocoDockButton(scale: chocoScale, onTap: onChocoTap),
          _DockItem(
            slot: 3,
            icon: Icons.calendar_month_rounded,
            label: 'Itinerario',
            selected: highlightSlot == 3,
            onTap: () => onTap(3),
          ),
          _DockItem(
            slot: 4,
            icon: Icons.payments_rounded,
            label: 'Gastos',
            selected: highlightSlot == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final int slot;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DockItem({
    required this.slot,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.text.withValues(alpha: 0.38),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.label(10.5, weight: selected ? FontWeight.w800 : FontWeight.w500).copyWith(
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.text.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChocoDockButton extends StatelessWidget {
  final Animation<double> scale;
  final VoidCallback onTap;

  const _ChocoDockButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: ScaleTransition(
              scale: scale,
                  child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.creamLight,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.85),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.38),
                    width: 2.0,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const ChocoNavLogo(size: 46, fit: BoxFit.contain),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.mic_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
