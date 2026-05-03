import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF3E8),
      body: Stack(
        children: [
          // 1. FONDO (Cielo/Montañas)
          Positioned.fill(
            child: Image.asset(
              'assets/images/cielo.png', 
              fit: BoxFit.cover,
            ),
          ),

          // wenas choco
          Positioned(
            right: -40,
            top: MediaQuery.of(context).size.height * 0.12, 
            child: Image.asset(
              'assets/images/choco_icon.png',
              width: MediaQuery.of(context).size.width * 0.9,
            ),
          ),

          // 3. TEXTOS Y BOTÓN
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vamos por una\nnueva choco aventura',
                    style: GoogleFonts.leckerliOne(
                      fontSize: 38,
                      color: const Color(0xFF4B3B2B),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Descubre el mejor viaje por el mundo\nacompañado de Choco',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF7A6F62),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // BOTÓN
                  ElevatedButton(
                    onPressed: () {
                      // Acción al presionar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7E8959),
                      minimumSize: const Size(180, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("¡Vamos!", style: TextStyle(color: Colors.white, fontSize: 18)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
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