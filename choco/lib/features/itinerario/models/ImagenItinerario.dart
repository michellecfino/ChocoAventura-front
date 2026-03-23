class Imagen {
  final int id;
  final String url;

  Imagen({required this.id, required this.url});

  factory Imagen.fromJson(Map<String, dynamic> json) {
    return Imagen(
      id: json['id'],
      url: json['url'],
    );
  }
}