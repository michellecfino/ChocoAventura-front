import 'package:choco/features/viajes/screens/CreacionGrupoViaje.dart';
import 'package:choco/features/voice_assistant/screens/voice_assistant_view.dart'; 
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");

  runApp(const MaterialApp(home: Prueba()));
}

class Prueba extends StatelessWidget {
  const Prueba({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: const CreacionGrupoViaje(), 
      
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VoiceAssistantView(
                apiKey: dotenv.get('AIzaSyBR-3AWpjm0uSGx4BymiKTmbXFHYcUOOoE'),
              ),
            ),
          );
        },
        child: const Icon(Icons.mic),
      ),
    );
  }
}