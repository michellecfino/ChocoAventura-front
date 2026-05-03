import 'package:flutter/material.dart';
import 'voice_assistant_service.dart'; // Importa el servicio de la respuesta anterior

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
      await _voiceService.stopListening();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });

      // Enviar a Gemini cuando termina de escuchar
      if (_transcript.isNotEmpty) {
        final result = await _voiceService.processTranscript(_transcript);
        setState(() {
          _extractedData = result;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
      }
    } else {
      setState(() {
        _transcript = '';
        _extractedData = null;
        _isListening = true;
      });
      
      await _voiceService.startListening(
        onResult: (text) {
          setState(() {
            _transcript = text;
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
              minHeight: 100,
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
                              ? _extractedData.toString() 
                              : 'Esperando datos...',
                          style: const TextStyle(fontFamily: 'monospace'),
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