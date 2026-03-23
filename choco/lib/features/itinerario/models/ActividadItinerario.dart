class ActividadItinerario{
  final int id;
  final String nombre;
  final double costo;
  final int duracion;

  ActividadItinerario({
    required this.id,
    required this.nombre,
    required this.costo,
    required this.duracion,
  });

  factory ActividadItinerario.fromJson(Map<String, dynamic> json) {
    return ActividadItinerario(
      id: json['id'],
      nombre: json['nombre'],
      costo: (json['costoPorPersona'] as num).toDouble(),
      duracion: json['duracionMin'],
    );
  }
}