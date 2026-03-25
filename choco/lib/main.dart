import 'package:choco/features/viajes/screens/CreacionGrupoViaje.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(MaterialApp(home: const Prueba()));
}

class Prueba extends StatelessWidget {
  const Prueba({super.key});

  @override
  Widget build(BuildContext context) {
    return CreacionGrupoViaje();
  }
}
