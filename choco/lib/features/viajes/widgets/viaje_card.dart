import 'package:flutter/material.dart';
import '../models/grupo_viaje_model.dart';

class ViajeCard extends StatelessWidget {
  final GrupoViajeModel viaje;
  final VoidCallback? onTap;

  const ViajeCard({
    super.key,
    required this.viaje,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(viaje.nombre),
        subtitle: Text('${viaje.destino} • ${viaje.participantes} participantes'),
        onTap: onTap,
      ),
    );
  }
}