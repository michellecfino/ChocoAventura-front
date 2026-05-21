import 'package:choco/core/services/api_client.dart';
import 'package:choco/features/itinerario/models/Itinerario.dart';

/// Servicio de itinerarios conectado al backend Spring Boot.
///
/// Endpoints consumidos:
///   GET  /itinerarios/{id}                → ItinerarioResponseDTO
///   POST /itinerarios                     → ItinerarioResponseDTO
///       body: { nombre: String, grupoViajeId: Long }
///
/// ItinerarioResponseDTO del back:
///   { id, nombre, presupuestoPromedioPersona,
///     dias: [ { fecha, items: [ { id, inicioProgramado, finProgramado,
///                                  estado, itinerarioId, actividad: {...} } ] } ] }
class ItinerarioService {
  const ItinerarioService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  bool get _backendConfigurado => _client.configurado;

  // ------------------------------------------------------------------
  // Obtener itinerario por id — GET /itinerarios/{id}
  // ------------------------------------------------------------------

  Future<Itinerario> getItinerario(int id, {int? usuarioId}) async {
    if (!_backendConfigurado) {
      throw Exception('Backend no configurado para cargar itinerarios.');
    }
    final suffix = usuarioId == null ? '' : '?usuarioId=$usuarioId';
    final data = await _client.get('/itinerarios/$id$suffix');
    return Itinerario.fromJson(data as Map<String, dynamic>);
  }


  Future<Itinerario> getItinerarioActualPorGrupo({
    required int grupoViajeId,
    int? usuarioId,
  }) async {
    if (!_backendConfigurado) {
      throw Exception('Backend no configurado para cargar itinerarios.');
    }
    final suffix = usuarioId == null ? '' : '?usuarioId=$usuarioId';
    final data = await _client.get('/itinerarios/grupos/$grupoViajeId/actual$suffix');
    return Itinerario.fromJson(data as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Crear itinerario — POST /itinerarios
  //
  // El backend lo genera automáticamente a partir de las actividades
  // que el grupo seleccionó durante la exploración grupal.
  // ------------------------------------------------------------------

  Future<Itinerario> crearItinerario({
    required String nombre,
    required int grupoViajeId,
  }) async {
    if (!_backendConfigurado) {
      throw Exception('Backend no configurado para crear itinerarios.');
    }
    final data = await _client.post('/itinerarios', {
      'nombre': nombre,
      'grupoViajeId': grupoViajeId,
    });
    return Itinerario.fromJson(data as Map<String, dynamic>);
  }
}
