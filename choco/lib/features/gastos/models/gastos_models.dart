import 'package:intl/intl.dart';

/// Estados alineados con el backend (`DEBES_PAGAR`, etc.).
enum EstadoViajeFinanciero {
  debesPagar('DEBES_PAGAR'),
  teDeben('TE_DEBEN'),
  pendiente('PENDIENTE'),
  saldado('SALDADO');

  final String apiValue;
  const EstadoViajeFinanciero(this.apiValue);

  static EstadoViajeFinanciero desdeApi(String? raw) {
    if (raw == null || raw.isEmpty) return EstadoViajeFinanciero.saldado;
    for (final e in EstadoViajeFinanciero.values) {
      if (e.apiValue == raw) return e;
    }
    return EstadoViajeFinanciero.saldado;
  }

  String etiquetaUsuario() {
    switch (this) {
      case EstadoViajeFinanciero.debesPagar:
        return 'Debes pagar';
      case EstadoViajeFinanciero.teDeben:
        return 'Te deben';
      case EstadoViajeFinanciero.pendiente:
        return 'Pendiente';
      case EstadoViajeFinanciero.saldado:
        return 'Saldado';
    }
  }

  /// Etiqueta corta para chips en tarjetas (sin “Pendiente” redundante como estado principal).
  String etiquetaTarjeta() {
    switch (this) {
      case EstadoViajeFinanciero.debesPagar:
        return 'Debes';
      case EstadoViajeFinanciero.teDeben:
        return 'Te deben';
      case EstadoViajeFinanciero.pendiente:
        return 'Cuentas por cerrar';
      case EstadoViajeFinanciero.saldado:
        return 'Saldado';
    }
  }
}

enum FiltroGastosChip {
  todos,
  pendientes,
  saldados,
}

enum TipoGastoForm {
  individual,
  compartido,
}

enum CategoriaGasto {
  comida('Comida'),
  transporte('Transporte'),
  actividad('Actividades'),
  hospedaje('Hospedaje'),
  otro('Otro');

  final String etiqueta;
  const CategoriaGasto(this.etiqueta);
}

enum TipoDivisionGasto {
  igual('Igual para todos'),
  montosExactos('Por montos exactos'),
  porcentajes('Por porcentajes');

  final String etiqueta;
  const TipoDivisionGasto(this.etiqueta);
}

class ViajeFinancieroResumen {
  final String idViaje;
  final String? idGrupo;
  final String nombreViaje;
  /// Clave de destino para assets y exploración (`bogota`, `cartagena`, …).
  final String? destinoKey;
  final EstadoViajeFinanciero estado;
  final double tuDebes;
  final double teDeben;
  final double hasGastado;
  final double presupuesto;
  /// Perfil del usuario en este viaje (mock / backend).
  final String perfilId;

  const ViajeFinancieroResumen({
    required this.idViaje,
    this.idGrupo,
    required this.nombreViaje,
    this.destinoKey,
    required this.estado,
    required this.tuDebes,
    required this.teDeben,
    required this.hasGastado,
    required this.presupuesto,
    this.perfilId = '1',
  });

  factory ViajeFinancieroResumen.fromJson(Map<String, dynamic> j) {
    return ViajeFinancieroResumen(
      idViaje: '${j['idViaje'] ?? j['idGrupo']}',
      idGrupo: j['idGrupo']?.toString(),
      nombreViaje: j['nombreViaje'] as String? ?? 'Viaje',
      destinoKey: j['destinoKey'] as String?,
      estado: EstadoViajeFinanciero.desdeApi(j['estado'] as String?),
      tuDebes: _toD(j['tuDebes']),
      teDeben: _toD(j['teDeben']),
      hasGastado: _toD(j['hasGastado']),
      presupuesto: _toD(j['presupuesto']),
      perfilId: '${j['perfilId'] ?? 1}',
    );
  }

  static double _toD(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

class PersonaMonto {
  final String id;
  final String nombre;
  final double monto;

  const PersonaMonto({
    required this.id,
    required this.nombre,
    required this.monto,
  });
}

class GastoRecienteItem {
  final String id;
  final String descripcion;
  final double monto;
  final DateTime fecha;
  final String categoria;

  const GastoRecienteItem({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.fecha,
    required this.categoria,
  });
}

class DetalleFinancieroViaje {
  final double presupuestoTotal;
  final double gastado;
  final double restante;
  final List<PersonaMonto> personasTuDebes;
  final List<PersonaMonto> personasTeDeben;
  final Map<String, double> resumenPorCategoria;
  final List<GastoRecienteItem> gastosRecientes;
  final String recomendacionChoco;
  final bool todoSaldado;

  const DetalleFinancieroViaje({
    required this.presupuestoTotal,
    required this.gastado,
    required this.restante,
    required this.personasTuDebes,
    required this.personasTeDeben,
    required this.resumenPorCategoria,
    required this.gastosRecientes,
    required this.recomendacionChoco,
    required this.todoSaldado,
  });

  factory DetalleFinancieroViaje.fromJson(Map<String, dynamic> j) {
    final tu = (j['personasTuDebes'] as List<dynamic>? ?? [])
        .map((e) => PersonaMonto(
              id: '${(e as Map)['perfilId']}',
              nombre: e['nombre'] as String? ?? '?',
              monto: ViajeFinancieroResumen._toD(e['monto']),
            ))
        .toList();
    final te = (j['personasTeDeben'] as List<dynamic>? ?? [])
        .map((e) => PersonaMonto(
              id: '${(e as Map)['perfilId']}',
              nombre: e['nombre'] as String? ?? '?',
              monto: ViajeFinancieroResumen._toD(e['monto']),
            ))
        .toList();
    final catMap = <String, double>{};
    final rawCat = j['resumenPorCategoria'];
    if (rawCat is Map) {
      rawCat.forEach((k, v) {
        catMap['$k'] = ViajeFinancieroResumen._toD(v);
      });
    }
    final rec = (j['gastosRecientes'] as List<dynamic>? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return GastoRecienteItem(
        id: '${m['id']}',
        descripcion: m['descripcion'] as String? ?? '',
        monto: ViajeFinancieroResumen._toD(m['monto']),
        fecha: DateTime.tryParse('${m['fecha']}') ?? DateTime.now(),
        categoria: m['categoria'] as String? ?? 'Otros',
      );
    }).toList();

    final todo = j['todoSaldado'] as bool? ?? (tu.isEmpty && te.isEmpty);

    return DetalleFinancieroViaje(
      presupuestoTotal: ViajeFinancieroResumen._toD(j['presupuestoTotal']),
      gastado: ViajeFinancieroResumen._toD(j['gastado']),
      restante: ViajeFinancieroResumen._toD(j['restante']),
      personasTuDebes: tu,
      personasTeDeben: te,
      resumenPorCategoria: catMap,
      gastosRecientes: rec,
      recomendacionChoco: j['recomendacionChoco'] as String? ?? '',
      todoSaldado: todo,
    );
  }
}

class InterpretacionChoco {
  final String descripcion;
  final double monto;
  final TipoGastoForm tipo;
  final String pagadorEtiqueta;
  final String participantesEtiqueta;
  final CategoriaGasto categoria;
  /// Si no está vacío, Choco necesita una respuesta antes de guardar.
  final List<String> preguntasPendientes;

  const InterpretacionChoco({
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.pagadorEtiqueta,
    required this.participantesEtiqueta,
    required this.categoria,
    this.preguntasPendientes = const [],
  });

  bool get necesitaMasDatos => preguntasPendientes.isNotEmpty;
}

/// Pesos colombianos: símbolo adelante y miles con punto (p. ej. $48.000).
final NumberFormat _copMiles = NumberFormat('#,##0', 'de_DE');

String formatoCop(double valor) {
  final n = valor.round();
  final neg = n < 0;
  final body = _copMiles.format(n.abs());
  return '${neg ? '-' : ''}\$$body';
}

/// Incluye sufijo COP cuando haga falta en UI.
String formatoCopConMoneda(double valor) => '${formatoCop(valor)} COP';
