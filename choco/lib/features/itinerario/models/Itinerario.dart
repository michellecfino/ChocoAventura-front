class Itinerario {
  final int id;
  final String nombre;
  final double presupuestoPromedioPersona;
  final List<DiaItinerario> dias;

  Itinerario({
    required this.id,
    required this.nombre,
    required this.presupuestoPromedioPersona,
    required this.dias,
  });

  factory Itinerario.fromJson(Map<String, dynamic> json) {
    return Itinerario(
      id: json['id'],
      nombre: json['nombre'],
      presupuestoPromedioPersona:
          (json['presupuestoPromedioPersona'] as num).toDouble(),
      dias: (json['dias'] as List)
          .map((d) => DiaItinerario.fromJson(d))
          .toList(),
    );
  }
}