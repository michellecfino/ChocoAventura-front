import 'ItemItinerario.dart';
class DiaItinerario {
  final DateTime fecha;
  final List<ItemItinerario> items;

  DiaItinerario({
    required this.fecha,
    required this.items,
  });

  factory DiaItinerario.fromJson(Map<String, dynamic> json) {
    return DiaItinerario(
      fecha: DateTime.parse(json['fecha']),
      items: (json['items'] as List)
          .map((i) => ItemItinerario.fromJson(i))
          .toList(),
    );
  }
}