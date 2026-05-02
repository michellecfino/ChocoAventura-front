import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/gastos_models.dart';

/// Servicio de gastos: usa datos mock por defecto y puede enlazar al backend real.
class GastosService {
  GastosService();

  /// Cambia a `true` y define `API_BASE_URL` en `.env` para consumir el backend.
  static bool get usarBackend {
    final raw = dotenv.maybeGet('API_BASE_URL') ?? dotenv.maybeGet('BACKEND_URL');
    return raw != null && raw.isNotEmpty && !raw.contains('TU_BACKEND');
  }

  String? get _baseUrl {
    final u = dotenv.maybeGet('API_BASE_URL') ?? dotenv.maybeGet('BACKEND_URL');
    if (u == null || u.isEmpty || u.contains('TU_BACKEND')) return null;
    var s = u.trim();
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  final List<ViajeFinancieroResumen> _mockViajes = [
    ViajeFinancieroResumen(
      idViaje: '1',
      nombreViaje: 'Cartagena',
      estado: EstadoViajeFinanciero.teDeben,
      tuDebes: 0,
      teDeben: 50000,
      hasGastado: 180000,
      presupuesto: 500000,
      perfilId: '1',
    ),
    ViajeFinancieroResumen(
      idViaje: '2',
      nombreViaje: 'Medellín',
      estado: EstadoViajeFinanciero.debesPagar,
      tuDebes: 45000,
      teDeben: 0,
      hasGastado: 230000,
      presupuesto: 400000,
      perfilId: '1',
    ),
    ViajeFinancieroResumen(
      idViaje: '3',
      nombreViaje: 'Eje Cafetero',
      estado: EstadoViajeFinanciero.saldado,
      tuDebes: 0,
      teDeben: 0,
      hasGastado: 410000,
      presupuesto: 450000,
      perfilId: '1',
    ),
    ViajeFinancieroResumen(
      idViaje: '4',
      nombreViaje: 'Santa Marta',
      estado: EstadoViajeFinanciero.pendiente,
      tuDebes: 12000,
      teDeben: 8000,
      hasGastado: 95000,
      presupuesto: 300000,
      perfilId: '1',
    ),
  ];

  Future<List<ViajeFinancieroResumen>> fetchViajesPorUsuario(int usuarioId) async {
    final base = _baseUrl;
    if (usarBackend && base != null) {
      try {
        final res = await http.get(Uri.parse('$base/gastos/usuarios/$usuarioId/viajes'));
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List<dynamic>;
          return list
              .map((e) => ViajeFinancieroResumen.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {
        // cae a mock
      }
    }
    return List<ViajeFinancieroResumen>.from(_mockViajes);
  }

  Future<DetalleFinancieroViaje> fetchDetalle({
    required String idGrupo,
    required String perfilId,
  }) async {
    final base = _baseUrl;
    if (usarBackend && base != null) {
      try {
        final res = await http.get(
          Uri.parse('$base/gastos/grupos/$idGrupo/perfiles/$perfilId'),
        );
        if (res.statusCode == 200) {
          return DetalleFinancieroViaje.fromJson(
            Map<String, dynamic>.from(jsonDecode(res.body) as Map),
          );
        }
      } catch (_) {}
    }
    return _detalleMock(idGrupo, perfilId);
  }

  DetalleFinancieroViaje _detalleMock(String idGrupo, String perfilId) {
    ViajeFinancieroResumen? encontrado;
    for (final e in _mockViajes) {
      if (e.idViaje == idGrupo) {
        encontrado = e;
        break;
      }
    }
    final v = encontrado ?? _mockViajes.first;

    final presupuesto = v.presupuesto;
    final gastado = v.hasGastado;
    final restante = (presupuesto - gastado).clamp(0.0, presupuesto).toDouble();

    final Map<String, double> cats = {
      'Comida': gastado * 0.35,
      'Transporte': gastado * 0.2,
      'Actividades': gastado * 0.25,
      'Hospedaje': gastado * 0.12,
      'Compras': gastado * 0.05,
      'Otros': gastado * 0.03,
    };

    final List<PersonaMonto> tu = v.tuDebes > 0
        ? [
            const PersonaMonto(id: '2', nombre: 'Juan', monto: 25000),
            const PersonaMonto(id: '3', nombre: 'Ana', monto: 20000),
          ]
        : [];
    final List<PersonaMonto> te = v.teDeben > 0
        ? [PersonaMonto(id: '4', nombre: 'Carlos', monto: v.teDeben)]
        : [];

    final todoSaldado = v.tuDebes <= 0 && v.teDeben <= 0;

    return DetalleFinancieroViaje(
      presupuestoTotal: presupuesto,
      gastado: gastado,
      restante: restante,
      personasTuDebes: tu,
      personasTeDeben: te,
      resumenPorCategoria: cats,
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
        GastoRecienteItem(
          id: 'g3',
          descripcion: 'Entrada museo',
          monto: 30000,
          fecha: DateTime.now().subtract(const Duration(days: 3)),
          categoria: 'Actividades',
        ),
      ],
      recomendacionChoco: todoSaldado
          ? 'Todo saldado: cuentas claras, aventura feliz.'
          : 'Para saldar este viaje solo necesitas 2 movimientos.',
      todoSaldado: todoSaldado,
    );
  }

  /// Registra un gasto (mock actualiza listas en memoria; backend usa POST).
  /// Prioridad: intenta **siempre** POST al backend cuando hay URL válida en `.env`.
  /// Solo usa mock si no hay config, falla la red o el servidor responde error.
  Future<void> registrarGasto({
    required String idGrupo,
    required String perfilId,
    required String descripcion,
    required double monto,
    required String tipoApi,
    required String categoria,
    String? pagadoPorPerfilId,
    List<String>? participantesIds,
    String? division,
    String? nota,
    String? detalleDivisionJson,
  }) async {
    final base = _baseUrl;
    if (usarBackend && base != null) {
      final body = <String, dynamic>{
        'grupoId': int.parse(idGrupo),
        'perfilId': int.parse(perfilId),
        'descripcion': descripcion,
        'monto': monto,
        'tipo': tipoApi,
        'categoria': categoria,
        'division': division,
        'nota': nota,
      };
      if (pagadoPorPerfilId != null) {
        body['pagadoPorPerfilId'] = int.parse(pagadoPorPerfilId);
      }
      if (participantesIds != null && participantesIds.isNotEmpty) {
        body['participantesIds'] = participantesIds.map(int.parse).toList();
      }
      if (detalleDivisionJson != null && detalleDivisionJson.isNotEmpty) {
        body['detalleDivision'] = detalleDivisionJson;
      }
      final res = await http.post(
        Uri.parse('$base/gastos/registrar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode >= 400) {
        throw Exception('No se pudo registrar el gasto');
      }
      return;
    }

    // Mock: incrementa "has gastado" del viaje y ajusta deudas de forma simple.
    final idx = _mockViajes.indexWhere((e) => e.idViaje == idGrupo);
    if (idx < 0) return;
    final ant = _mockViajes[idx];
    final nuevoGastado = ant.hasGastado + monto * (tipoApi == 'COMPARTIDO' ? 0.25 : 1.0);
    _mockViajes[idx] = ViajeFinancieroResumen(
      idViaje: ant.idViaje,
      nombreViaje: ant.nombreViaje,
      estado: ant.estado,
      tuDebes: ant.tuDebes,
      teDeben: ant.teDeben,
      hasGastado: nuevoGastado,
      presupuesto: ant.presupuesto,
      perfilId: ant.perfilId,
    );
  }

  List<ViajeFinancieroResumen> viajesMockActuales() => List.from(_mockViajes);

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
      final mencionaTodos =
          lower.contains('todos') || lower.contains('grupo') || lower.contains('para todos');
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
}
