import 'package:flutter/material.dart';
import '../../../app/colors.dart';

class ItemWidget extends StatelessWidget {
  final ItemItinerario item;

  const ItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = getEstadoColor(item.estado);

    final imagen = item.actividad.imagenes.isNotEmpty
        ? item.actividad.imagenes.first.url
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          if (imagen != null)
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Image.network(
                imagen,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.actividad.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${_formatHora(item.inicio)} - ${_formatHora(item.fin)}",
                    style: TextStyle(color: AppColors.text.withOpacity(0.7)),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "\$${item.actividad.costo.toInt()}",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _formatHora(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}