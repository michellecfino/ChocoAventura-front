class ItemItinerario {
  final int id;
  final DateTime inicio;
  final DateTime fin;
  final String estado;
  final Actividad actividad;

  ItemItinerario({
    required this.id,
    required this.inicio,
    required this.fin,
    required this.estado,
    required this.actividad,
  });

  factory ItemItinerario.fromJson(Map<String, dynamic> json) {
    return ItemItinerario(
      id: json['id'],
      inicio: DateTime.parse(json['inicioProgramado']),
      fin: DateTime.parse(json['finProgramado']),
      estado: json['estado'],
      actividad: Actividad.fromJson(json['actividad']),
    );
  }
}