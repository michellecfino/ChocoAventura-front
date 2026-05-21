import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP base para todos los servicios de ChocoAventura.
///
/// Centraliza:
/// - La URL base (desde .env → API_BASE_URL o BACKEND_URL)
/// - Headers comunes (Content-Type, Authorization futura)
/// - Manejo de errores HTTP genérico
///
/// Uso:
///   final client = ApiClient();
///   final data = await client.get('/categorias');
///   final body = await client.post('/usuarios/login', {'correo': ..., 'contrasena': ...});
class ApiClient {
  const ApiClient();

  // ------------------------------------------------------------------
  // Base URL
  // ------------------------------------------------------------------

  String get baseUrl {
    final u = dotenv.maybeGet('API_BASE_URL') ?? dotenv.maybeGet('BACKEND_URL') ?? '';
    var s = u.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  bool get configurado => baseUrl.isNotEmpty && !baseUrl.contains('TU_BACKEND');

  // ------------------------------------------------------------------
  // Headers
  // ------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Cuando agregues JWT:
        // if (token != null) 'Authorization': 'Bearer $token',
      };

  // ------------------------------------------------------------------
  // Métodos HTTP
  // ------------------------------------------------------------------

  /// GET [path] → retorna el body decodificado (Map o List)
  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _manejarRespuesta(res);
  }

  /// POST [path] con [body] → retorna el body decodificado
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _manejarRespuesta(res);
  }

  /// PUT [path] con [body] → retorna el body decodificado
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _manejarRespuesta(res);
  }

  /// DELETE [path] → retorna el body decodificado (puede ser String)
  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _manejarRespuesta(res);
  }

  // ------------------------------------------------------------------
  // Manejo de respuestas
  // ------------------------------------------------------------------

  dynamic _manejarRespuesta(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body; // Respuesta de texto plano (ej: mensajes de éxito)
      }
    }

    // Intentar extraer mensaje de error del body
    String? mensaje;
    try {
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      mensaje = m['error'] as String? ?? m['message'] as String?;
    } catch (_) {}

    throw ApiException(
      statusCode: res.statusCode,
      mensaje: mensaje ?? 'Error en la petición (${res.statusCode})',
    );
  }
}

/// Excepción tipada para errores HTTP.
class ApiException implements Exception {
  final int statusCode;
  final String mensaje;

  const ApiException({required this.statusCode, required this.mensaje});

  @override
  String toString() => 'ApiException($statusCode): $mensaje';
}
