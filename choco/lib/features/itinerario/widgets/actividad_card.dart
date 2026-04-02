import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActividadCard extends StatelessWidget {
  final String nombre;
  final String imagenUrl;
  final String precio;
  final String ubicacion;

  const ActividadCard({
    super.key,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
    required this.ubicacion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // 1. Imagen de fondo (La que traeremos con el scraping que dijiste)
            Image.network(
              imagenUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              // Esto es por si la imagen falla, que no se rompa la app
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF5E6CA),
                child: const Icon(Icons.broken_image, size: 50, color: Colors.brown),
              ),
            ),

            // 2. Degradado para que el texto resalte (Como en el Figma)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // 3. Información de la actividad
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFF5E6CA), size: 18),
                      const SizedBox(width: 5),
                      Text(
                        ubicacion,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6F4E37), // Café Choco
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "Desde $precio",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}