import 'package:choco/core/services/api_client.dart';
import '../models/gastos_models.dart';

/// Servicio de gastos conectado al backend Spring Boot.
///
/// Endpoints consumidos:
///   GET  /gastos/usuarios/{usuarioId}/viajes         → List<ViajeFinancieroDTO>
///   GET  /gastos/grupos/{grupoId}/perfiles/{perfilId} → DetalleFinancieroDTO
///   POST /gastos/registrar                            → GastoRegistradoDTO
///   PUT  /gastos/deudas/{deudaId}/saldar              → 204 No Content
///
/// Mapeo back → front:
///   ViajeFinancieroDTO  → ViajeFinancieroResumen
///   DetalleFinancieroDTO → DetalleFinancieroViaje
///   PersonaMontoDTO     → PersonaMonto  (perfilId → id, nombre, monto)
///   GastoRecienteDTO    → GastoRecienteItem
class GastosService {
  GastosService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  bool get _usarBackend => _client.configurado;

  // ------------------------------------------------------------------
  // Listar viajes financieros — GET /gastos/usuarios/{usuarioId}/viajes
  // ------------------------------------------------------------------

  Future<List<ViajeFinancieroResumen>> fetchViajesPorUsuario(int usuarioId) async {
    if (!_usarBackend || usuarioId <= 0) return <ViajeFinancieroResumen>[];
    final list = await _client.get('/gastos/usuarios/$usuarioId/viajes') as List<dynamic>;
    return list
        .map((e) => ViajeFinancieroResumen.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ------------------------------------------------------------------
  // Detalle financiero — GET /gastos/grupos/{grupoId}/perfiles/{perfilId}
  // ------------------------------------------------------------------

  Future<DetalleFinancieroViaje> fetchDetalle({
    required String idGrupo,
    required String perfilId,
  }) async {
    if (!_usarBackend) throw Exception('Backend no configurado para gastos');
    final data = await _client.get('/gastos/grupos/$idGrupo/perfiles/$perfilId');
    return DetalleFinancieroViaje.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  // ------------------------------------------------------------------
  // Registrar gasto — POST /gastos/registrar
  //
  // Body → RegistrarGastoRequestDTO:
  //   grupoId, perfilId, descripcion, monto, tipo, categoria,
  //   pagadoPorPerfilId?, participantesIds?, division?, nota?, detalleDivision?
  // ------------------------------------------------------------------

  Future<void> registrarGasto({
    required String idGrupo,
    required String perfilId,
    required String descripcion,
    required double monto,
    required String tipoApi,         // 'INDIVIDUAL' | 'COMPARTIDO'
    required String categoria,
    String? pagadoPorPerfilId,
    List<String>? participantesIds,
    String? division,
    String? nota,
    String? detalleDivisionJson,
  }) async {
    if (_usarBackend) {
      final body = <String, dynamic>{
        'grupoId': int.parse(idGrupo),
        'perfilId': int.parse(perfilId),
        'descripcion': descripcion,
        'monto': monto,
        'tipo': tipoApi,
        'categoria': categoria,
        if (division != null) 'division': division,
        if (nota != null) 'nota': nota,
        if (pagadoPorPerfilId != null)
          'pagadoPorPerfilId': int.parse(pagadoPorPerfilId),
        if (participantesIds != null && participantesIds.isNotEmpty)
          'participantesIds': participantesIds.map(int.parse).toList(),
        if (detalleDivisionJson != null && detalleDivisionJson.isNotEmpty)
          'detalleDivision': detalleDivisionJson,
      };

      await _client.post('/gastos/registrar', body);
      return;
    }
    throw Exception('Backend no configurado para registrar gastos');
  }

  // ------------------------------------------------------------------
  // Saldar deuda — PUT /gastos/deudas/{deudaId}/saldar
  // ------------------------------------------------------------------

  Future<void> saldarDeuda(int deudaId) async {
    if (_usarBackend) {
      await _client.put('/gastos/deudas/$deudaId/saldar', {});
      return;
    }
    // Mock: no-op
  }

  // ------------------------------------------------------------------
  // Interpretación de texto libre (local, sin backend)
  // ------------------------------------------------------------------

  InterpretacionChoco interpretarTextoLibre(String texto) {
    final lower = texto.toLowerCase();
    double monto = 40000;
    final mil = RegExp(r'(\d+)\s*mil');
    final mMil = mil.firstMatch(lower);
    if (mMil != null) {
      monto = double.parse(mMil.group(1)!) * 1000;
    } else {
      final nums = RegExp(r'(\d+)').firstMatch(lower);
      if (nums != null) {
        final n = double.tryParse(nums.group(1)!);
        if (n != null && n > 500) monto = n;
      }
    }

    var tipo = TipoGastoForm.compartido;
    if (lower.contains('solo') || lower.contains('mío') || lower.contains('mio')) {
      tipo = TipoGastoForm.individual;
    }

    var cat = CategoriaGasto.transporte;
    if (lower.contains('cena') || lower.contains('comida') || lower.contains('almuerzo')) {
      cat = CategoriaGasto.comida;
    } else if (lower.contains('hotel') || lower.contains('hostal')) {
      cat = CategoriaGasto.hospedaje;
    } else if (lower.contains('taxi') || lower.contains('uber') || lower.contains('bus')) {
      cat = CategoriaGasto.transporte;
    }

    var desc = 'Gasto';
    if (lower.contains('taxi')) desc = 'Taxi';
    if (lower.contains('cena')) desc = 'Cena';

    final preguntas = <String>[];
    if (tipo == TipoGastoForm.compartido) {
      final mencionaTodos = lower.contains('todos') ||
          lower.contains('grupo') ||
          lower.contains('para todos');
      final mencionaNombres =
          RegExp(r'\b(ana|juan|carlos|maria|pedro|luis)\b').hasMatch(lower);
      if (mencionaTodos && !mencionaNombres) {
        preguntas.add('¿Confirmamos que participaron todas las personas del viaje?');
      }
      if (!mencionaTodos && !mencionaNombres) {
        preguntas.add('¿Quiénes participaron en este gasto compartido?');
      }
    }

    return InterpretacionChoco(
      descripcion: desc,
      monto: monto,
      tipo: tipo,
      pagadorEtiqueta: 'Yo',
      participantesEtiqueta: 'Todos',
      categoria: cat,
      preguntasPendientes: preguntas,
    );
  }

  List<ViajeFinancieroResumen> viajesMockActuales() => List.from(_mockViajes);

  // ------------------------------------------------------------------
  // Mocks
  // ------------------------------------------------------------------

  final List<ViajeFinancieroResumen> _mockViajes = [
    ViajeFinancieroResumen(
      idViaje: '1',
      nombreViaje: 'Parche costeño',
      destinoKey: 'cartagena',
      estado: EstadoViajeFinanciero.teDeben,
      tuDebes: 0,
      teDeben: 50000,
      hasGastado: 180000,
      presupuesto: 500000,
      perfilId: '1',
    ),
    ViajeFinancieroResumen(
      idViaje: '2',
      nombreViaje: 'Paisa weekend',
      destinoKey: 'medellin',
      estado: EstadoViajeFinanciero.debesPagar,
      tuDebes: 45000,
      teDeben: 0,
      hasGastado: 230000,
      presupuesto: 400000,
      perfilId: '1',
    ),
    ViajeFinancieroResumen(
      idViaje: '3',
      nombreViaje: 'Capital cultural',
      destinoKey: 'bogota',
      estado: EstadoViajeFinanciero.saldado,
      tuDebes: 0,
      teDeben: 0,
      hasGastado: 410000,
      presupuesto: 450000,
      perfilId: '1',
    ),
  ];

  DetalleFinancieroViaje _detalleMock(String idGrupo, String perfilId) {
    ViajeFinancieroResumen? v;
    for (final e in _mockViajes) {
      if (e.idViaje == idGrupo) {
        v = e;
        break;
      }
    }
    v ??= _mockViajes.first;

    final gastado = v.hasGastado;
    final restante = (v.presupuesto - gastado).clamp(0.0, v.presupuesto).toDouble();

    final tu = v.tuDebes > 0
        ? [
            const PersonaMonto(id: '2', nombre: 'Juan', monto: 25000),
            const PersonaMonto(id: '3', nombre: 'Ana', monto: 20000),
          ]
        : <PersonaMonto>[];
    final te = v.teDeben > 0
        ? [PersonaMonto(id: '4', nombre: 'Carlos', monto: v.teDeben)]
        : <PersonaMonto>[];

    return DetalleFinancieroViaje(
      presupuestoTotal: v.presupuesto,
      gastado: gastado,
      restante: restante,
      personasTuDebes: tu,
      personasTeDeben: te,
      resumenPorCategoria: {
        'Comida': gastado * 0.38,
        'Transporte': gastado * 0.22,
        'Actividades': gastado * 0.26,
        'Hospedaje': gastado * 0.14,
      },
      gastosRecientes: [
        GastoRecienteItem(
          id: 'g1',
          descripcion: 'Almuerzo grupo',
          monto: 120000,
          fecha: DateTime.now().subtract(const Duration(days: 1)),
          categoria: 'Comida',
        ),
        GastoRecienteItem(
          id: 'g2',
          descripcion: 'Taxi aeropuerto',
          monto: 45000,
          fecha: DateTime.now().subtract(const Duration(days: 2)),
          categoria: 'Transporte',
        ),
      ],
      recomendacionChoco: tu.isEmpty && te.isEmpty
          ? 'Todo saldado: cuentas claras, aventura feliz.'
          : 'Para saldar este viaje solo necesitas 2 movimientos.',
      todoSaldado: tu.isEmpty && te.isEmpty,
    );
  }
}
