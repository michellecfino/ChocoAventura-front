class GrupoViajeModel {
  final int? id;
  final String nombre;
  final String destino;
  final String? fechaInicio;
  final String? fechaFin;
  final int participantes;

  GrupoViajeModel({
    this.id,
    required this.nombre,
    required this.destino,
    this.fechaInicio,
    this.fechaFin,
    required this.participantes,
  });

  factory GrupoViajeModel.fromJson(Map<String, dynamic> json) {
    return GrupoViajeModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      destino: json['destino'] ?? '',
      fechaInicio: json['fechaInicio'],
      fechaFin: json['fechaFin'],
      participantes: json['participantes'] ?? 0,
    );
  }
}