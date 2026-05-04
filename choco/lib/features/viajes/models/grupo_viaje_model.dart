/// Participante mock para la demo del flujo grupal.
class ParticipanteMock {
  final String nombre;
  final bool listo;
  const ParticipanteMock({required this.nombre, required this.listo});
}

ViajeFaseProducto _parseFase(String? raw) {
  if (raw == null || raw.isEmpty) return ViajeFaseProducto.explorarActividades;
  for (final e in ViajeFaseProducto.values) {
    if (e.name == raw) return e;
  }
  return ViajeFaseProducto.explorarActividades;
}

/// Fase del flujo de producto (UI / datos de ejemplo).
enum ViajeFaseProducto {
  crearViaje,
  invitar,
  preferencias,
  explorarActividades,
  /// Tras explorar: esperando votos del grupo antes de la mesa.
  esperaGrupoVotacion,
  priorizacionCategorias,
  mesaChoco,
  itinerarioGenerado,
  ajustesItinerario,
  viajeActivo,
  /// Enfoque en liquidación de gastos del viaje.
  gastosViaje,
}

extension ViajeFaseProductoX on ViajeFaseProducto {
  String get etiquetaCorta {
    switch (this) {
      case ViajeFaseProducto.crearViaje:
        return 'Creación';
      case ViajeFaseProducto.invitar:
        return 'Invitaciones';
      case ViajeFaseProducto.preferencias:
        return 'Preferencias';
      case ViajeFaseProducto.explorarActividades:
        return 'Explorar planes';
      case ViajeFaseProducto.esperaGrupoVotacion:
        return 'Esperando al grupo';
      case ViajeFaseProducto.mesaChoco:
        return 'Mesa de Choco';
      case ViajeFaseProducto.priorizacionCategorias:
        return 'Prioridades';
      case ViajeFaseProducto.itinerarioGenerado:
        return 'Itinerario listo';
      case ViajeFaseProducto.ajustesItinerario:
        return 'Ajustes';
      case ViajeFaseProducto.viajeActivo:
        return 'En viaje';
      case ViajeFaseProducto.gastosViaje:
        return 'Gastos del viaje';
    }
  }

  /// Texto del botón principal en la card de Viajes.
  String get ctaPrincipal {
    switch (this) {
      case ViajeFaseProducto.explorarActividades:
        return 'Explorar actividades';
      case ViajeFaseProducto.esperaGrupoVotacion:
        return 'Ver estado del grupo';
      case ViajeFaseProducto.itinerarioGenerado:
      case ViajeFaseProducto.ajustesItinerario:
      case ViajeFaseProducto.viajeActivo:
        return 'Ver itinerario';
      case ViajeFaseProducto.crearViaje:
      case ViajeFaseProducto.invitar:
      case ViajeFaseProducto.preferencias:
        return 'Continuar';
      case ViajeFaseProducto.mesaChoco:
        return 'Ir a la Mesa de Choco';
      case ViajeFaseProducto.priorizacionCategorias:
        return 'Prioriza tu aventura';
      case ViajeFaseProducto.gastosViaje:
        return 'Ir a gastos';
    }
  }
}

class GrupoViajeModel {
  final int? id;
  final String nombreViaje;
  final String destinoKey;
  final String destinoNombre;
  final String ciudadDepartamento;
  final String? fechaInicio;
  final String? fechaFin;
  final int participantes;
  final String estadoDisplay;
  final ViajeFaseProducto faseActual;
  final String itinerarioEstado;
  final String codigoInvitacion;
  final String linkInvitacion;

  /// Texto corto para hub de itinerario (solo viajes con plan listo / en viaje).
  final String? proximaActividadTexto;

  /// Participantes del viaje con estado de exploración (solo demo).
  final List<ParticipanteMock>? participantesList;

  GrupoViajeModel({
    this.id,
    required this.nombreViaje,
    required this.destinoKey,
    required this.destinoNombre,
    required this.ciudadDepartamento,
    this.fechaInicio,
    this.fechaFin,
    required this.participantes,
    this.estadoDisplay = 'Activo',
    this.faseActual = ViajeFaseProducto.explorarActividades,
    this.itinerarioEstado = 'En construcción',
    required this.codigoInvitacion,
    required this.linkInvitacion,
    this.proximaActividadTexto,
    this.participantesList,
  });

  /// Compatibilidad con UI que aún usa `nombre` / `destino`.
  String get nombre => nombreViaje;

  String get destino => ciudadDepartamento;

  factory GrupoViajeModel.fromJson(Map<String, dynamic> json) {
    return GrupoViajeModel(
      id: json['id'],
      nombreViaje: json['nombreViaje'] as String? ?? json['nombre'] as String? ?? '',
      destinoKey: json['destinoKey'] as String? ?? 'cartagena',
      destinoNombre: json['destinoNombre'] as String? ?? '',
      ciudadDepartamento: json['ciudadDepartamento'] as String? ?? json['destino'] as String? ?? '',
      fechaInicio: json['fechaInicio'] as String?,
      fechaFin: json['fechaFin'] as String?,
      participantes: json['participantes'] ?? 0,
      estadoDisplay: json['estadoDisplay'] as String? ?? 'Activo',
      faseActual: _parseFase(json['faseActual'] as String?),
      itinerarioEstado: json['itinerarioEstado'] as String? ?? 'En construcción',
      codigoInvitacion: json['codigoInvitacion'] as String? ?? 'CHOCO-000',
      linkInvitacion: json['linkInvitacion'] as String? ?? 'https://chocoaventura.app/invitacion',
      proximaActividadTexto: json['proximaActividadTexto'] as String?,
    );
  }
}
