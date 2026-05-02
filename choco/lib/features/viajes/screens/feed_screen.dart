import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/features/viajes/widgets/viaje_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.paddingOf(context).top;

    final viajes = [
      GrupoViajeModel(
        id: 1,
        nombre: 'Cartagena mágica',
        destino: 'Cartagena, Bolívar',
        participantes: 5,
        estadoDisplay: 'Activo',
      ),
      GrupoViajeModel(
        id: 2,
        nombre: 'Medellín city break',
        destino: 'Medellín, Antioquia',
        participantes: 4,
        estadoDisplay: 'Activo',
      ),
      GrupoViajeModel(
        id: 3,
        nombre: 'Eje Cafetero express',
        destino: 'Quindío',
        participantes: 3,
        estadoDisplay: 'Próximo',
      ),
      GrupoViajeModel(
        id: 4,
        nombre: 'Santa Marta & Tayrona',
        destino: 'Santa Marta, Magdalena',
        participantes: 6,
        estadoDisplay: 'Activo',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, topSafe + 12, AppSpacing.md, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus aventuras',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Retoma el ritmo donde lo dejaste',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: viajes
                    .map(
                      (v) => ViajeCard(
                        viaje: v,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Pronto abriremos el detalle de ${v.nombre}',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
