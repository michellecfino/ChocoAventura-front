import 'package:choco/core/services/api_client.dart';

/// Servicio de coordinación (Mesa de Choco / Subasta de actividades).
///
/// Endpoints consumidos:
///   --- Rondas de subasta ---
///   POST /rondas-subasta          → RondaSubasta
///   GET  /rondas-subasta          → List<RondaSubasta>
///   GET  /rondas-subasta/{id}     → RondaSubasta
///   PUT  /rondas-subasta/{id}     → RondaSubasta
///
///   --- Asignación de tokens ---
///   POST /asignaciones-tokens     → AsignacionTokens
///   GET  /asignaciones-tokens     → List<AsignacionTokens>
///   GET  /asignaciones-tokens/{id} → AsignacionTokens
///   PUT  /asignaciones-tokens/{id} → AsignacionTokens
///
/// Nota: la Mesa de Choco (exploración grupal) se coordina a través de:
///   GET  /grupos/{grupoId}/exploracion-grupal/estado
///   POST /grupos/{grupoId}/exploracion-grupal/confirmar
///   GET  /grupos/{grupoId}/exploracion-grupal
/// Esos están en ViajesService para mantener la cohesión.
class CoordinacionService {
  const CoordinacionService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  bool get _backendConfigurado => _client.configurado;

  // ------------------------------------------------------------------
  // Rondas de subasta
  // ------------------------------------------------------------------

  /// Crea una ronda de subasta. El body debe incluir los campos de RondaSubasta.
  Future<Map<String, dynamic>> crearRonda(Map<String, dynamic> ronda) async {
    if (!_backendConfigurado) return {...ronda, 'id': 1};
    final data = await _client.post('/rondas-subasta', ronda);
    return data as Map<String, dynamic>;
  }

  /// Lista todas las rondas de subasta.
  Future<List<Map<String, dynamic>>> listarRondas() async {
    if (!_backendConfigurado) return [];
    final list = await _client.get('/rondas-subasta') as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Obtiene una ronda por id.
  Future<Map<String, dynamic>> getRonda(int id) async {
    if (!_backendConfigurado) return {'id': id};
    final data = await _client.get('/rondas-subasta/$id');
    return data as Map<String, dynamic>;
  }

  /// Actualiza una ronda (ej: registrar voto / bid de un participante).
  Future<Map<String, dynamic>> actualizarRonda(int id, Map<String, dynamic> ronda) async {
    if (!_backendConfigurado) return {...ronda, 'id': id};
    final data = await _client.put('/rondas-subasta/$id', ronda);
    return data as Map<String, dynamic>;
  }

  // ------------------------------------------------------------------
  // Asignación de tokens
  // ------------------------------------------------------------------

  /// Crea o actualiza la asignación de tokens de un perfil en una ronda.
  ///
  /// Body esperado por el back (AsignacionTokens):
  ///   { perfil: { id }, rondaSubasta: { id }, tokensAsignados: int, actividad: { id }? }
  Future<Map<String, dynamic>> crearAsignacion(Map<String, dynamic> asignacion) async {
    if (!_backendConfigurado) return {...asignacion, 'id': 1};
    final data = await _client.post('/asignaciones-tokens', asignacion);
    return data as Map<String, dynamic>;
  }

  /// Lista todas las asignaciones de tokens.
  Future<List<Map<String, dynamic>>> listarAsignaciones() async {
    if (!_backendConfigurado) return [];
    final list = await _client.get('/asignaciones-tokens') as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Actualiza la asignación de tokens de un perfil (bid en una ronda).
  Future<Map<String, dynamic>> actualizarAsignacion(
      int id, Map<String, dynamic> asignacion) async {
    if (!_backendConfigurado) return {...asignacion, 'id': id};
    final data = await _client.put('/asignaciones-tokens/$id', asignacion);
    return data as Map<String, dynamic>;
  }
}
