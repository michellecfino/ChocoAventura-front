import 'package:flutter/material.dart';
import '../models/grupo_viaje_model.dart';
import '../widgets/viaje_card.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viajes = [
      GrupoViajeModel(
        id: 1,
        nombre: 'Viaje a Medellín',
        destino: 'Medellín',
        participantes: 4,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tus viajes')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viajes.length,
        itemBuilder: (context, index) {
          return ViajeCard(viaje: viajes[index]);
        },
      ),
    );
  }
}