import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:choco/app/colors.dart';
import '../widgets/actividad_card.dart';

class ExploracionScreen extends StatefulWidget {
  const ExploracionScreen({super.key});

  @override
  State<ExploracionScreen> createState() => _ExploracionScreenState();
}

class _ExploracionScreenState extends State<ExploracionScreen> {
  final List<Map<String, String>> actividadesPrueba = [
    {
      "nombre": "Monserrate",
      "imagenUrl": "https://bogotadc.travel/sites/default/files/2020-09/monserrate-bogota-cerros.jpg",
      "precio": "\$27.000",
      "ubicacion": "Cerros Orientales",
    },
    {
      "nombre": "Andrés Carne de Res",
      "imagenUrl": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRz-8Z1Z7_LgGZpYp9-7h6z",
      "precio": "\$80.000",
      "ubicacion": "Chía / Zona T",
    },
    {
      "nombre": "Museo Botero",
      "imagenUrl": "https://www.banrepcultural.org/sites/default/files/styles/flexslider_full/public/museo_botero_0.jpg",
      "precio": "Gratis",
      "ubicacion": "La Candelaria",
    },
  ];

  final CardSwiperController controller = CardSwiperController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Preparamos la lista de widgets antes (porque tu versión pide 'cards')
    List<Widget> cardsList = actividadesPrueba.map((item) {
      return ActividadCard(
        nombre: item['nombre']!,
        imagenUrl: item['imagenUrl']!,
        precio: item['precio']!,
        ubicacion: item['ubicacion']!,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Descubre Bogotá",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Desliza a la derecha si te gusta, o a la izquierda para pasar.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: CardSwiper(
                controller: controller,
                cards: cardsList, // <--- Aquí usamos 'cards' como pide tu error
                onSwipe: (index, direction) { // Cambié los argumentos aquí también
                  if (direction == CardSwiperDirection.right) {
                    debugPrint("¡Le gustó!");
                  }
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _botonAccion(Icons.close, Colors.red, () => controller.swipeLeft()),
                  _botonAccion(Icons.favorite, Colors.green, () => controller.swipeRight()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonAccion(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}