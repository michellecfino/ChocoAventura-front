class ActividadItinerario {
  final int id;
  final String nombre;
  final double costo;
  final int duracion;
  final List<Imagen> imagenes;

  ActividadItinerario({
    required this.id,
    required this.nombre,
    required this.costo,
    required this.duracion,
    required this.imagenes,
  });

  factory ActividadItinerario.fromJson(Map<String, dynamic> json) {
    return ActividadItinerario(
      id: json['id'],
      nombre: json['nombre'],
      costo: (json['costoPorPersona'] as num).toDouble(),
      duracion: json['duracionMin'],
      imagenes: (json['imagenes'] as List)
          .map((i) => Imagen.fromJson(i))
          .toList(),
    );
  }
}