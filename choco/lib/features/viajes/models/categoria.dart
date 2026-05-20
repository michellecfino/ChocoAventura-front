class Categoria {
  final int id;
  final String nombre;
  final String descripcion;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  // 🔸 Convertir de JSON a objeto
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  // 🔸 Convertir de objeto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}