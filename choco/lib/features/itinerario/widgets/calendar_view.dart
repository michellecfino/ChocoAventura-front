import 'package:flutter/material.dart';
import '../models/DiaItinerario.dart';
import 'package:choco/features/itinerario/models/ItemItinerario.dart';
import 'package:choco/app/colors.dart';

class CalendarDayView extends StatelessWidget {
  final DiaItinerario dia;

  const CalendarDayView({super.key, required this.dia});

  @override
Widget build(BuildContext context) {

  return LayoutBuilder( 
    builder: (context, constraints) {
      final dynamicHourHeight = constraints.maxHeight / 24;

      return InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(0),
        minScale: 1.0, 
        maxScale: 4.0,
        child: Container(
          color: Colors.white,
 
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          child: Stack(
            children: [
              _buildHourLines(dynamicHourHeight),
              ...dia.items.map((item) => _buildEvent(context, item, dynamicHourHeight)),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildHourLines(double hHeight) {
  return Column(
    children: List.generate(24, (hour) {
      return Container(
        height: hHeight,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
            children: [
              SizedBox(
                width: 45,
                child: Text(
                  "${hour.toString().padLeft(2, '0')}:00",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              const Expanded(child: Divider(height: 1, color: Colors.black12)),
            ],
          ),
      );
    }),
  );
  }

  Widget _buildEvent(BuildContext context, ItemItinerario item, double hHeight) {
    final start = item.inicio;
    final end = item.fin;

    final startMinutes = start.hour * 60 + start.minute;
    final duration = end.difference(start).inMinutes;

    final top = (startMinutes * hHeight) / 60;
    final height = (duration * hHeight) / 60;

    final colorEstado = getEstadoColor(item.estado);

    return Positioned(
      top: top,
      left: 55,
      right: 10,
      height: height > 0 ? height : 20,
      child: GestureDetector(
        onTap: () => _showDetail(context, item),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorEstado.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: colorEstado, width: 3)),
          ),
          child: Text(
            item.actividad.nombre,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 9, 
              fontWeight: FontWeight.bold
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Color getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA': return Colors.green;
      case 'EN_CURSO': return Colors.blue;
      case 'PROGRAMADA': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showDetail(BuildContext context, ItemItinerario item) {
  final actividad = item.actividad;
  final colorEstado = getEstadoColor(item.estado);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      // Envolvemos todo en un SingleChildScrollView por si la descripción 
      // es muy larga y la pantalla es pequeña, para que no haya desbordamiento.
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGEN
              if (actividad.imagenes.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    actividad.imagenes.first.url,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. NOMBRE Y CALIFICACIÓN (En la misma fila)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            actividad.nombre,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (actividad.calificacionPromedio != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  actividad.calificacionPromedio.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. ESTADO
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorEstado),
                      ),
                      child: Text(
                        item.estado,
                        style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. DIRECCIÓN (Con icono de ubicación)
                    if (actividad.direccion != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              actividad.direccion!,
                              style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                    ],

                    // 5. DESCRIPCIÓN
                    if (actividad.descripcion != null) ...[
                      Text(
                        actividad.descripcion!,
                        style: const TextStyle(
                          fontSize: 14, 
                          height: 1.5, // Le da un poco más de espacio entre líneas para que sea fácil de leer
                          color: Colors.black87
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],

                    // 6. HORA Y COSTO
                    const Divider(color: Colors.black12), // Una línea sutil para separar
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "${item.inicio.hour.toString().padLeft(2, '0')}:${item.inicio.minute.toString().padLeft(2, '0')} - "
                              "${item.fin.hour.toString().padLeft(2, '0')}:${item.fin.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: Colors.green, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              "\$${actividad.costo.toInt()}",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }
}