import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cliente generativo opcional (Groq/Gemini). Si no hay clave, no se usa y no rompe la app.
class ChocoGenerativoOpcional {
  ChocoGenerativoOpcional._();

  static bool get hayClaveConfigurada {
    final g = dotenv.maybeGet('GROQ_API_KEY')?.trim() ?? '';
    final m = dotenv.maybeGet('GEMINI_API_KEY')?.trim() ?? '';
    return g.isNotEmpty || m.isNotEmpty;
  }

  /// Reservado para una futura llamada HTTP con contexto de viaje. Por ahora siempre null.
  static Future<String?> complementarConModelo({
    required String preguntaUsuario,
    required String contextoApp,
  }) async {
    if (!hayClaveConfigurada) return null;
    return null;
  }
}
