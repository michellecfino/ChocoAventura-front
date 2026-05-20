import 'package:choco/core/services/api_client.dart';
import 'package:choco/features/auth/models/usuario_model.dart';

/// Servicio de autenticación conectado al backend Spring Boot.
///
/// Endpoints consumidos:
///   POST /usuarios/login    → { correo, contrasena }
///   POST /usuarios/registro → { nombre, correo, contrasena }
///
/// Respuesta esperada (LoginResponseDTO del back):
///   { id: Long, nombre: String, correo: String }
class AuthService {
  const AuthService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  // ------------------------------------------------------------------
  // Login
  // ------------------------------------------------------------------

  /// Inicia sesión. Retorna [UsuarioModel] o lanza [AuthException].
  Future<UsuarioModel> login({
    required String correo,
    required String contrasena,
  }) async {
    if (!_client.configurado) {
      throw const AuthException('Backend no configurado para iniciar sesión.');
    }

    try {
      final data = await _client.post('/usuarios/login', {
        'correo': correo,
        'contrasena': contrasena,
      }) as Map<String, dynamic>;
      return UsuarioModel.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw AuthException(e.mensaje.isNotEmpty
            ? e.mensaje
            : 'Correo o contraseña incorrectos.');
      }
      throw AuthException('Error del servidor (${e.statusCode}). Intenta más tarde.');
    }
  }

  // ------------------------------------------------------------------
  // Registro
  // ------------------------------------------------------------------

  /// Registra un nuevo usuario. Retorna [UsuarioModel] o lanza [AuthException].
  Future<UsuarioModel> registro({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    if (!_client.configurado) {
      throw const AuthException('Backend no configurado para crear la cuenta.');
    }

    try {
      final data = await _client.post('/usuarios/registro', {
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      }) as Map<String, dynamic>;
      return UsuarioModel.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw const AuthException('Ya existe una cuenta con este correo.');
      }
      throw AuthException(
        e.mensaje.isNotEmpty
            ? e.mensaje
            : 'No se pudo crear la cuenta. Intenta de nuevo.',
      );
    }
  }

  // ------------------------------------------------------------------
  // Mocks de desarrollo
  // ------------------------------------------------------------------

  UsuarioModel _mockLogin(String correo, String contrasena) {
    if (contrasena.length < 3) throw const AuthException('Contraseña incorrecta (mock).');
    return UsuarioModel(id: 1, nombre: 'Usuario Demo', correo: correo);
  }

  UsuarioModel _mockRegistro(String nombre, String correo) {
    return UsuarioModel(id: 99, nombre: nombre, correo: correo);
  }
}

/// Excepción tipada para errores de autenticación.
class AuthException implements Exception {
  final String mensaje;
  const AuthException(this.mensaje);

  @override
  String toString() => mensaje;
}
