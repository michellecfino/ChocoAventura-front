import 'package:flutter/material.dart';
import '../widgets/home_action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChocoAventura')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HomeActionCard(
            titulo: 'Empieza a organizar tu viaje',
            subtitulo: 'Explora destinos y actividades',
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
          const SizedBox(height: 12),
          const HomeActionCard(
            titulo: 'Continúa organizando tus viajes',
            subtitulo: 'Tus viajes activos aparecerán aquí',
          ),
        ],
      ),
    );
  }
}