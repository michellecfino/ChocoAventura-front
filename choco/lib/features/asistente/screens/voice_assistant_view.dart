import 'package:flutter/material.dart';
import 'dart:convert'; // IMPORTANTE: Necesario para formatear el JSON
import '../services/voice_assistant_service.dart';

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
          // Tu servicio ya nos entrega el texto cuando detecta el final (finalResult)
          setState(() {
            _transcript = text;
            _isListening = false; // Apagamos el micrófono rojo
            _isProcessing = true; // Encendemos el cargador del JSON
          });

          // Llamamos a Gemini automáticamente sin necesidad de presionar un botón
          final result = await _voiceService.processTranscript(text);
          
          setState(() {
            _extractedData = result;
            _isProcessing = false;
          });
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
                          // Aquí le damos el formato bonito al JSON
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