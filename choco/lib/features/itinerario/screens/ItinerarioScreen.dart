import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/Itinerario.dart';
import '../services/ItinerarioService.dart';
import '../widgets/calendar_view.dart';
import 'ExploracionScreen.dart';

import 'package:choco/app/colors.dart';

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
    //itinerario = Future.value(Itinerario.fromJson(itinerarioMock));
    itinerario = ItinerarioService().getItinerario(widget.itinerarioId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerario>(
      future: itinerario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Error")));
        }

        final data = snapshot.data!;

        if (data.dias.isEmpty) {
          return const Center(child: Text("No hay itinerario"));
        }

        return DefaultTabController(
          length: data.dias.length,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                data.nombre,
                style: GoogleFonts.poppins(
                  // Puedes probar también con .montserrat() o .caveat()
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors
                      .black, // Asegúrate de que contraste con tu AppColors.primary
                  letterSpacing: 1.2, // Le da un poco de respiro a las letras
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.primary,

              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.text,
                tabs: List.generate(
                  data.dias.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Tab(text: "Día ${index + 1}"),
                  ),
                ),
              ),
            ),

            body: TabBarView(
              children: data.dias
                  .map((dia) => CalendarDayView(dia: dia))
                  .toList(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExploracionScreen(),
                  ),
                );
              },
              label: Text(
                "Explorar más",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.explore),
              backgroundColor: AppColors.accent,
            ),
          ),
        );
      },
    );
  }
}
