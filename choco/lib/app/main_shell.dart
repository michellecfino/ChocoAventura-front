import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/widgets/mobile_app_frame.dart';
import 'package:choco/features/gastos/screens/gastos_screen.dart';
import 'package:choco/features/gastos/services/gastos_service.dart';
import 'package:choco/features/gastos/widgets/choco_assistant_sheet.dart';
import 'package:choco/features/gastos/widgets/choco_illustration.dart';
import 'package:choco/features/home/screens/home_screen.dart';
import 'package:choco/features/itinerario/screens/ItinerarioScreen.dart';
import 'package:choco/features/viajes/screens/feed_screen.dart';
import 'package:flutter/material.dart';

/// Navegación: Inicio | Viajes | **Choco** | Itinerario | Gastos
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  final GastosService _gastosService = GastosService();
  final GlobalKey<GastosScreenState> _gastosKey = GlobalKey<GastosScreenState>();

  /// 0 Inicio, 1 Viajes, 2 Itinerario, 3 Gastos
  int _pageIndex = 0;

  late AnimationController _chocoPulse;
  late Animation<double> _chocoPulseScale;

  static const _itinerarioDemoId = 1;

  @override
  void initState() {
    super.initState();
    _chocoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _chocoPulseScale = Tween<double>(begin: 1.0, end: 1.07).animate(
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
          const ItinerarioScreen(itinerarioId: _itinerarioDemoId),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > MobileAppFrame.maxWidth + 32;
                final bar = _DockNavBar(
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

class _DockNavBar extends StatelessWidget {
  final int highlightSlot;
  final Animation<double> chocoScale;
  final void Function(int slot) onTap;
  final VoidCallback onChocoTap;

  const _DockNavBar({
    required this.highlightSlot,
    required this.chocoScale,
    required this.onTap,
    required this.onChocoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWarm,
            blurRadius: 20,
            offset: const Offset(0, -4),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primaryDark : AppColors.text.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.label(10, weight: selected ? FontWeight.w800 : FontWeight.w600).copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.text.withValues(alpha: 0.5),
                ),
              ),
            ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ScaleTransition(
          scale: scale,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.creamLight,
                  AppColors.surfaceMuted,
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: ChocoIllustration(size: 51, borderRadius: 25, variantSeed: 11, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.mic_rounded, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
