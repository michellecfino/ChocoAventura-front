import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class UserModel {
  final int? id;
  final String nombre;
  final String correo;

  const UserModel({this.id, required this.nombre, required this.correo});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int?,
        nombre: (json['nombre'] as String?) ?? '',
        correo: (json['correo'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'correo': correo};
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth result
// ─────────────────────────────────────────────────────────────────────────────
sealed class AuthResult {}

class AuthSuccess extends AuthResult {
  final UserModel user;
  AuthSuccess(this.user);
}

class AuthError extends AuthResult {
  final String message;
  AuthError(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────
// UserSession — singleton ChangeNotifier
// ─────────────────────────────────────────────────────────────────────────────
class UserSession extends ChangeNotifier {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal() {
    _loadFromStorage();
  }

  UserModel? _user;
  bool _loading = false;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  String get nombreDisplay => _user?.nombre ?? 'viajero';

  static const _storageKey = 'choco_session';

  void _loadFromStorage() {
    try {
      final stored = sessionRead(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final data = jsonDecode(stored) as Map<String, dynamic>;
        _user = UserModel.fromJson(data);
      }
    } catch (_) {}
  }

  String get _backendBase {
    try {
      return dotenv.env['API_BASE_URL'] ??
          dotenv.env['API_URL'] ??
          'http://localhost:8080';
    } catch (_) {
      return 'http://localhost:8080';
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login(String correo, String password) async {
    if (correo.trim().isEmpty || password.isEmpty) {
      return AuthError('Completa todos los campos.');
    }
    _loading = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$_backendBase/usuarios/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': correo.trim(), 'contrasena': password}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return _applyUser(UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>));
      } else if (res.statusCode == 401) {
        return _fail('Correo o contraseña incorrectos.');
      } else {
        return _fail('Error al iniciar sesión. Intenta de nuevo.');
      }
    } on TimeoutException {
      return _fail('No se pudo conectar con el backend para iniciar sesión.');
    } catch (_) {
      return _fail('No se pudo conectar con el backend para iniciar sesión.');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<AuthResult> register(String nombre, String correo, String password) async {
    if (nombre.trim().isEmpty || correo.trim().isEmpty || password.isEmpty) {
      return AuthError('Completa todos los campos.');
    }
    if (password.length < 4) {
      return AuthError('La contraseña debe tener al menos 4 caracteres.');
    }
    _loading = true;
    notifyListeners();

    try {
      final res = await http
          .post(
            Uri.parse('$_backendBase/usuarios/registro'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre.trim(),
              'correo': correo.trim(),
              'contrasena': password,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return _applyUser(UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>));
      } else if (res.statusCode == 409) {
        return _fail('Ya existe una cuenta con este correo.');
      } else {
        return _fail('No se pudo crear la cuenta. Intenta de nuevo.');
      }
    } on TimeoutException {
      return _fail('No se pudo conectar con el backend para crear la cuenta.');
    } catch (_) {
      return _fail('No se pudo conectar con el backend para crear la cuenta.');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  void logout() {
    _user = null;
    sessionRemove(_storageKey);
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  AuthResult _applyUser(UserModel user) {
    _user = user;
    try {
      sessionWrite(_storageKey, jsonEncode(user.toJson()));
    } catch (_) {}
    _loading = false;
    notifyListeners();
    return AuthSuccess(user);
  }

  AuthResult _fail(String msg) {
    _loading = false;
    notifyListeners();
    return AuthError(msg);
  }

  // ── Mock fallback (backend unavailable) ──────────────────────────────────

  final List<Map<String, dynamic>> _mockUsers = [
    {'id': 1, 'nombre': 'Valentina', 'correo': 'vale@chocoaventura.app', 'contrasena': '1234'},
    {'id': 2, 'nombre': 'Andrés', 'correo': 'andres@demo.com', 'contrasena': '1234'},
  ];

  AuthResult _mockLogin(String correo, String password) {
    final u = _mockUsers.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['correo'] == correo && u?['contrasena'] == password,
          orElse: () => null,
        );
    if (u == null) {
      return _fail(
        'Correo o contraseña incorrectos.\n'
        'Demo disponible: vale@chocoaventura.app / 1234',
      );
    }
    return _applyUser(UserModel.fromJson(u));
  }

  AuthResult _mockRegister(String nombre, String correo, String password) {
    if (_mockUsers.any((u) => u['correo'] == correo)) {
      return _fail('Ya existe una cuenta con este correo.');
    }
    final newUser = {'id': null, 'nombre': nombre, 'correo': correo};
    _mockUsers.add({...newUser, 'contrasena': password});
    return _applyUser(UserModel.fromJson(newUser));
  }
}
