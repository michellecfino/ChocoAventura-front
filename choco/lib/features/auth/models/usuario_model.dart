class UsuarioModel {
  final int id;
  final String nombre;
  final String correo;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'correo': correo,
      };
}
