import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final String apiKey;
  bool _isInitialized = false;

  VoiceAssistantService({required this.apiKey});

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Error de reconocimiento de voz: $error'),
        onStatus: (status) => print('Estado del micrófono: $status'),
      );
    }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (_isInitialized && !_speechToText.isListening) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: 'es_CO',
      );
    }
  }

  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  Future<Map<String, dynamic>?> processTranscript(String transcript) async {
    // URL de Groq (Si usas OpenAI, la URL es https://api.openai.com/v1/chat/completions)
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final systemPrompt = '''
      Actúas como un motor de extracción de entidades (NER). Tu única salida debe ser un objeto JSON válido.
      Clasifica la entrada en "CREATE_TRIP" o "ADD_EXPENSE".
      Estructura esperada:
      {
        "intent": "CREATE_TRIP",
        "data": {
          "destination": "string",
          "budget": 123
        }
      }
      Si un dato no está, usa null.
    ''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', 
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': transcript}
          ],
          'temperature': 0.1, // Temperatura baja para respuestas estructuradas
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        // Groq/OpenAI devuelven el texto dentro de choices[0].message.content
        final contentString = jsonResponse['choices'][0]['message']['content'];
        return jsonDecode(contentString);
      } else {
        print('Error en la API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error procesando NLP: $e');
      return null;
    }
  }
}