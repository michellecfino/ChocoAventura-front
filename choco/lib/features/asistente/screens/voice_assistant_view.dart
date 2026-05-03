import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/voice_assistant_service.dart';
import 'package:choco/features/viajes/screens/CreacionGrupoViaje.dart';

class VoiceAssistantView extends StatefulWidget {
  final String apiKey;

  const VoiceAssistantView({super.key, required this.apiKey});

  @override
  State<VoiceAssistantView> createState() => _VoiceAssistantViewState();
}

class _VoiceAssistantViewState extends State<VoiceAssistantView> {
  late final VoiceAssistantService _voiceService;
  
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcript = '';
  Map<String, dynamic>? _extractedData;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceAssistantService(apiKey: widget.apiKey);
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    await _voiceService.initialize();
  }

  // --- NUEVA FUNCIÓN AÑADIDA ---
  void _manejarNavegacion(Map<String, dynamic>? jsonResult) {
    if (jsonResult == null) return;

    if (jsonResult['intent'] == 'CREATE_TRIP') {
      final tripData = jsonResult['data'] as Map<String, dynamic>? ?? {};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreacionGrupoViaje(
            datosAsistente: tripData, 
          ),
        ),
      );
    } else if (jsonResult['intent'] == 'ADD_EXPENSE') {
      // 1. Imprimimos en consola para confirmación técnica
      print('Intención detectada: ADD_EXPENSE. Navegación en pausa.');

      // 2. Mostramos un aviso visual en la aplicación sin romper el flujo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Función de agregar gastos en construcción..."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Parada manual (si el usuario presiona el botón rojo antes de que termine solo)
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        if (_transcript.isNotEmpty && _extractedData == null) {
          _isProcessing = true;
        }
      });

      if (_transcript.isNotEmpty && _extractedData == null) {
        final result = await _voiceService.processTranscript(_transcript);
        setState(() {
          _extractedData = result;
          _isProcessing = false;
        });
        
        // Llamamos a la navegación aquí
        _manejarNavegacion(result);
      }
    } else {
      // Iniciar a escuchar
      setState(() {
        _transcript = 'Escuchando...';
        _extractedData = null;
        _isListening = true;
      });
      
      await _voiceService.startListening(
        onResult: (text) async {
          // El servicio nos entrega el texto cuando detecta el final
          setState(() {
            _transcript = text;
            _isListening = false; // Apagamos el micrófono rojo
            _isProcessing = true; // Encendemos el cargador del JSON
          });

          // Llamamos a Groq/Gemini automáticamente
          final result = await _voiceService.processTranscript(text);
          
          setState(() {
            _extractedData = result;
            _isProcessing = false;
          });

          // Llamamos a la navegación de forma automática
          _manejarNavegacion(result);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente ChocoAventuras'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Texto reconocido:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: Text(
                _transcript.isEmpty ? 'Presiona el micrófono y habla...' : _transcript,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Datos Extraídos (JSON):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isProcessing 
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _extractedData != null 
                              ? const JsonEncoder.withIndent('  ').convert(_extractedData) 
                              : 'Esperando datos...',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}