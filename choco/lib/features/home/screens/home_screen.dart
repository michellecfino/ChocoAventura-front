import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/features/gastos/widgets/choco_illustration.dart';
import 'package:choco/features/home/widgets/home_action_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _HomeHero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  HomeActionCard(
                    titulo: 'Crear una nueva aventura',
                    subtitulo: 'Define destino, fechas y convoca a tu equipo',
                    icon: Icons.add_road_rounded,
                    accent: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HomeActionCard(
                    titulo: 'Continuar mis viajes',
                    subtitulo: 'Entra a Viajes y retoma lo que ya empezaste',
                    icon: Icons.luggage_rounded,
                    accent: AppColors.text.withValues(alpha: 0.85),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Abre la pestaña Viajes abajo para ver tus aventuras.',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HomeActionCard(
                    titulo: 'Explorar en modo invitado',
                    subtitulo: 'Mira cómo se organiza un grupo antes de unirte',
                    icon: Icons.travel_explore_rounded,
                    accent: AppColors.accent.withValues(alpha: 0.95),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Pronto tendrás un recorrido guiado sin cuenta.',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      );
                    },
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

class _HomeHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;

    return Container(
      margin: EdgeInsets.fromLTRB(AppSpacing.md, topSafe + 10, AppSpacing.md, 4),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            Color.lerp(AppColors.primary, AppColors.background, 0.25)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, viajero!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choco te acompaña\nen cada paso',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Organiza acuerdos, itinerario y gastos del grupo con calma.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipOval(
              child: ChocoIllustration(size: 88, borderRadius: 44, variantSeed: 0),
            ),
          ),
        ],
      ),
    );
  }
}
