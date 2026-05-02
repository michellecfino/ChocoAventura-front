class GrupoViajeModel {
  final int? id;
  final String nombre;
  final String destino;
  final String? fechaInicio;
  final String? fechaFin;
  final int participantes;

  /// Chip corto: "Activo", "Próximo", etc.
  final String estadoDisplay;

  GrupoViajeModel({
    this.id,
    required this.nombre,
    required this.destino,
    this.fechaInicio,
    this.fechaFin,
    required this.participantes,
    this.estadoDisplay = 'Activo',
  });

  factory GrupoViajeModel.fromJson(Map<String, dynamic> json) {
    return GrupoViajeModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      destino: json['destino'] ?? '',
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      participantes: json['participantes'] ?? 0,
      estadoDisplay: json['estadoDisplay'] as String? ?? 'Activo',
    );
  }
}