import 'dart:convert';
import 'package:choco/features/viajes/models/UnirseGrupoDTO.dart';
import 'package:choco/features/viajes/models/categoria.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Servicio de grupos de viaje conectado al backend Spring Boot.
///
/// Endpoints consumidos:
///   GET  /categorias                    → List<Categoria>
///   GET  /grupos/usuarios/{usuarioId}   → List<GrupoViajeModel>
///   POST /grupos/crear                  → GrupoViajeModel
///   POST /grupos/unirse                 → String (mensaje)
///   GET  /grupos/{grupoId}/invitacion   → String (link)
class ViajesService {
  const ViajesService();

  String get _baseUrl {
    final u = dotenv.maybeGet('API_BASE_URL') ?? dotenv.maybeGet('BACKEND_URL') ?? '';
    var s = u.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  bool get _backendConfigurado =>
      _baseUrl.isNotEmpty && !_baseUrl.contains('TU_BACKEND');

  // ------------------------------------------------------------------
  // Categorías
  // ------------------------------------------------------------------

  /// GET /categorias
  /// Retorna la lista de categorías de actividad para que el usuario
  /// elija sus preferencias al unirse a un grupo.
  Future<List<Categoria>> getCategorias() async {
    if (!_backendConfigurado) return _categoriaMock();

    final res = await http.get(Uri.parse('$_baseUrl/categorias'));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar categorías (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // Viajes del usuario
  // ------------------------------------------------------------------

  /// GET /grupos/usuarios/{usuarioId}
  /// Retorna todos los grupos en los que el usuario participa.
  /// Flutter lo usa en feed_screen.dart para mostrar la lista de viajes.
  Future<List<GrupoViajeModel>> cargarViajesUsuario(int usuarioId) async {
    if (!_backendConfigurado || usuarioId <= 0) return <GrupoViajeModel>[];

    final res = await http.get(
      Uri.parse('$_baseUrl/grupos/usuarios/$usuarioId'),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => GrupoViajeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar viajes del usuario (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // Crear grupo
  // ------------------------------------------------------------------

  /// POST /grupos/crear
  /// Crea un nuevo grupo de viaje y retorna el grupo creado.
  /// Flutter lo usa en CreacionGrupoViaje.dart.
  ///
  /// [dto] debe contener al menos:
  ///   nombre, nombreCiudad, paisCiudad, fechaInicio, fechaFin, duenoId
  Future<GrupoViajeModel> crearViaje(Map<String, dynamic> dto) async {
    if (!_backendConfigurado) {
      throw Exception('Backend no configurado para crear viajes');
    }

    final res = await http.post(
      Uri.parse('$_baseUrl/grupos/crear'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto),
    );

    if (res.statusCode == 200) {
      return GrupoViajeModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    }
    throw Exception('No se pudo crear el viaje (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // Unirse a grupo
  // ------------------------------------------------------------------

  /// GET /grupos/codigo/{codigo}
  /// Valida el código antes de pedir presupuesto y categorías.
  Future<GrupoViajeModel> validarCodigoInvitacion(String codigo) async {
    if (!_backendConfigurado) throw Exception('Backend no configurado para validar códigos');

    final limpio = Uri.encodeComponent(_normalizarCodigo(codigo));
    final res = await http.get(Uri.parse('$_baseUrl/grupos/codigo/$limpio'));
    if (res.statusCode == 200) {
      return GrupoViajeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Código inválido o viaje no encontrado (${res.statusCode})');
  }

  /// POST /grupos/unirse
  /// Une al usuario al grupo con el DTO de preferencias.
  /// Flutter lo usa en la pantalla de unirse por código/link.
  Future<GrupoViajeModel> unirseAGrupo(UnirseGrupoDTO dto) async {
    if (!_backendConfigurado) throw Exception('Backend no configurado para unirse a grupos');

    final res = await http.post(
      Uri.parse('$_baseUrl/grupos/unirse'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dto.toJson()),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return GrupoViajeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Error al unirse al grupo (${res.statusCode}): ${res.body}');
  }

  String _normalizarCodigo(String raw) {
    var code = raw.trim();
    if (code.contains('/')) {
      final parts = code.split('/').where((p) => p.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) code = parts.last;
    }
    return code.toUpperCase();
  }

  // ------------------------------------------------------------------
  // Estado de exploración por viaje y usuario
  // ------------------------------------------------------------------

  Future<EstadoExploracionGrupo?> obtenerEstadoExploracion({
    required int grupoViajeId,
    int? usuarioId,
  }) async {
    if (!_backendConfigurado) return null;
    final q = usuarioId == null ? '' : '?usuarioId=$usuarioId';
    final res = await http.get(Uri.parse('$_baseUrl/grupos/$grupoViajeId/exploracion-grupal/estado$q'));
    if (res.statusCode == 200) {
      return EstadoExploracionGrupo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Error al cargar estado de exploración (${res.statusCode})');
  }

  // ------------------------------------------------------------------
  // Link de invitación
  // ------------------------------------------------------------------

  /// GET /grupos/{grupoId}/invitacion
  /// Obtiene el link de invitación para compartir el grupo.
  Future<String> obtenerLinkInvitacion(int grupoId) async {
    if (!_backendConfigurado) {
      return 'chocoaventura://grupo/$grupoId';
    }

    final res = await http.get(
      Uri.parse('$_baseUrl/grupos/$grupoId/invitacion'),
    );

    if (res.statusCode == 200) return res.body;
    throw Exception('No se pudo obtener el link de invitación');
  }

  // ------------------------------------------------------------------
  // Mocks de desarrollo
  // ------------------------------------------------------------------

  List<Categoria> _categoriaMock() => [
        Categoria(id: 1, nombre: 'Aventura', descripcion: 'Deportes extremos y naturaleza'),
        Categoria(id: 2, nombre: 'Cultura', descripcion: 'Historia, arte y gastronomía'),
        Categoria(id: 3, nombre: 'Relax', descripcion: 'Spa, playa y descanso'),
        Categoria(id: 4, nombre: 'Gastronomía', descripcion: 'Restaurantes y experiencias culinarias'),
        Categoria(id: 5, nombre: 'Fiesta', descripcion: 'Vida nocturna y entretenimiento'),
      ];

  List<GrupoViajeModel> _viajesMock() => [
        GrupoViajeModel(
          id: 1,
          nombreViaje: 'Parche costeño',
          destinoKey: 'cartagena',
          destinoNombre: 'Cartagena',
          ciudadDepartamento: 'Cartagena, Colombia',
          fechaInicio: '2025-07-10T08:00:00',
          fechaFin: '2025-07-14T20:00:00',
          participantes: 4,
          estadoDisplay: 'Activo',
          faseActual: ViajeFaseProducto.explorarActividades,
          itinerarioEstado: 'En construcción',
          codigoInvitacion: 'CHOCO-001',
          linkInvitacion: 'chocoaventura://grupo/1',
        ),
        GrupoViajeModel(
          id: 2,
          nombreViaje: 'Paisa weekend',
          destinoKey: 'medellin',
          destinoNombre: 'Medellín',
          ciudadDepartamento: 'Medellín, Colombia',
          fechaInicio: '2025-08-01T08:00:00',
          fechaFin: '2025-08-03T20:00:00',
          participantes: 3,
          estadoDisplay: 'Activo',
          faseActual: ViajeFaseProducto.viajeActivo,
          itinerarioEstado: 'Listo',
          codigoInvitacion: 'CHOCO-002',
          linkInvitacion: 'chocoaventura://grupo/2',
        ),
      ];
}

class ParticipanteEstadoGrupo {
  final int? perfilId;
  final int? usuarioId;
  final String nombre;
  final bool listo;

  const ParticipanteEstadoGrupo({
    this.perfilId,
    this.usuarioId,
    required this.nombre,
    required this.listo,
  });

  factory ParticipanteEstadoGrupo.fromJson(Map<String, dynamic> json) {
    return ParticipanteEstadoGrupo(
      perfilId: (json['perfilId'] as num?)?.toInt(),
      usuarioId: (json['usuarioId'] as num?)?.toInt(),
      nombre: json['nombre'] as String? ?? 'Participante',
      listo: json['listo'] == true,
    );
  }
}

class EstadoExploracionGrupo {
  final int grupoId;
  final String estadoGrupo;
  final bool todosLosPerfilesListos;
  final bool requiereConfirmacionDueno;
  final int totalParticipantes;
  final int perfilesListos;
  final int faltanPorExplorar;
  final String mensaje;
  final bool usuarioActualExploro;
  final bool usuarioActualDebeExplorar;
  final bool usuarioActualPuedeExplorar;
  final List<ParticipanteEstadoGrupo> participantes;

  const EstadoExploracionGrupo({
    required this.grupoId,
    required this.estadoGrupo,
    required this.todosLosPerfilesListos,
    required this.requiereConfirmacionDueno,
    required this.totalParticipantes,
    required this.perfilesListos,
    required this.faltanPorExplorar,
    required this.mensaje,
    required this.usuarioActualExploro,
    required this.usuarioActualDebeExplorar,
    required this.usuarioActualPuedeExplorar,
    required this.participantes,
  });

  bool get mesaHabilitada => todosLosPerfilesListos;

  factory EstadoExploracionGrupo.fromJson(Map<String, dynamic> json) {
    final participantesRaw = json['participantes'] as List<dynamic>? ?? const [];
    final total = (json['totalParticipantes'] as num?)?.toInt() ??
        (json['totalPerfilesDecisores'] as num?)?.toInt() ??
        participantesRaw.length;
    final listos = (json['perfilesListos'] as num?)?.toInt() ??
        participantesRaw.where((e) => e is Map && e['listo'] == true).length;
    return EstadoExploracionGrupo(
      grupoId: (json['grupoId'] as num?)?.toInt() ?? 0,
      estadoGrupo: json['estadoGrupo'] as String? ?? '',
      todosLosPerfilesListos: json['todosLosPerfilesListos'] == true || json['todosListos'] == true,
      requiereConfirmacionDueno: json['requiereConfirmacionDueno'] == true,
      totalParticipantes: total,
      perfilesListos: listos,
      faltanPorExplorar: (json['faltanPorExploracion'] as num?)?.toInt() ??
          (json['faltanPorExplorar'] as num?)?.toInt() ??
          ((total - listos).clamp(0, total) as num).toInt(),
      mensaje: json['mensaje'] as String? ?? '',
      usuarioActualExploro: json['usuarioActualExploro'] == true,
      usuarioActualDebeExplorar: json['usuarioActualDebeExplorar'] == true,
      usuarioActualPuedeExplorar: json['usuarioActualPuedeExplorar'] == true,
      participantes: participantesRaw
          .whereType<Map>()
          .map((e) => ParticipanteEstadoGrupo.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
