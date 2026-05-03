import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  late final GenerativeModel _model;
  bool _isInitialized = false;

  VoiceAssistantService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system('''
        Actúas como un motor de extracción de entidades (NER). Tu única salida debe ser un objeto JSON válido. No incluyas saludos, explicaciones ni formato markdown de bloques de código.

        Clasifica la entrada de voz en uno de dos intents: "CREATE_TRIP" o "ADD_EXPENSE". Si no corresponde a ninguno, usa "UNKNOWN".
        Extrae los datos basándote en esta estructura y reglas:

        Estructura JSON esperada:
        {
          "intent": "CREATE_TRIP" | "ADD_EXPENSE" | "UNKNOWN",
          "data": {
            "tripName": string | null,
            "destination": string | null,
            "dateRange": string | null,
            "amount": number | null, 
            "description": string | null,
            "payer": string | null,
            "participants": array de strings | null 
          }
        }

        Reglas de extracción:
        - Para CREATE_TRIP: Busca Nombre del viaje, Destino y Rango de fechas.
        - Para ADD_EXPENSE: Busca Monto (conviértelo a un número entero, ej. "45 mil" -> 45000), Descripción (motivo del gasto), Quién pagó (payer) y Participantes. Si el gasto es para todos, el array de participants debe ser ["ALL"].
        - Si un dato no se menciona en la entrada, su valor debe ser estrictamente null.
      '''),
    );
  }

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
    try {
      final response = await _model.generateContent([Content.text(transcript)]);
      
      if (response.text != null) {
        return jsonDecode(response.text!); 
      }
      return null;
    } catch (e) {
      print('Error procesando NLP con Gemini: $e');
      return null;
    }
  }
}