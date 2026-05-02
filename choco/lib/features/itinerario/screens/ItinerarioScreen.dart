import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/features/itinerario/models/Itinerario.dart';
import 'package:choco/features/itinerario/services/ItinerarioService.dart';
import 'package:choco/features/itinerario/widgets/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItinerarioScreen extends StatefulWidget {
  final int itinerarioId;

  const ItinerarioScreen({super.key, required this.itinerarioId});

  @override
  State<ItinerarioScreen> createState() => _ItinerarioScreenState();
}

class _ItinerarioScreenState extends State<ItinerarioScreen> {
  late Future<Itinerario> itinerario;

  @override
  void initState() {
    super.initState();
    itinerario = ItinerarioService().getItinerario(widget.itinerarioId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerario>(
      future: itinerario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
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
            body: Center(
              child: Text(
                'Aún no hay días en este itinerario',
                style: GoogleFonts.poppins(color: AppColors.text),
              ),
            ),
          );
        }

        return DefaultTabController(
          length: data.dias.length,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                data.nombre,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.outlineSoft),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: AppColors.text,
                      unselectedLabelColor: AppColors.text.withValues(alpha: 0.55),
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: List.generate(
                        data.dias.length,
                        (index) => Tab(text: 'Día ${index + 1}'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            body: Container(
              margin: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.md),
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
                children: data.dias.map((dia) => CalendarDayView(dia: dia)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
