import 'ImagenItinerario.dart';

class ActividadItinerario {
  final int id;
  final String nombre;
  final String? descripcion; // Añadido
  final double costo;
  final int duracion;
  final double? calificacionPromedio; // Añadido
  final DateTime? vigenciaInicio; // Añadido
  final DateTime? vigenciaFin; // Añadido
  final String? preciosDetallados; // Añadido
  final String? fuente; // Añadido
  final String? direccion; // Añadido
  final List<Imagen> imagenes;

  ActividadItinerario({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.costo,
    required this.duracion,
    this.calificacionPromedio,
    this.vigenciaInicio,
    this.vigenciaFin,
    this.preciosDetallados,
    this.fuente,
    this.direccion,
    required this.imagenes,
  });

  factory ActividadItinerario.fromJson(Map<String, dynamic> json) {
    return ActividadItinerario(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      
      // Manejo seguro de números (por si el backend envía un int en vez de double o viene null)
      costo: json['costoPorPersona'] != null ? (json['costoPorPersona'] as num).toDouble() : 0.0,
      duracion: json['duracionMin'] ?? 0,
      
      calificacionPromedio: json['calificacionPromedio'] != null 
          ? (json['calificacionPromedio'] as num).toDouble() 
          : null,
          
      // Parseo seguro de fechas de String a DateTime
      vigenciaInicio: json['vigenciaInicio'] != null 
          ? DateTime.tryParse(json['vigenciaInicio']) 
          : null,
      vigenciaFin: json['vigenciaFin'] != null 
          ? DateTime.tryParse(json['vigenciaFin']) 
          : null,
          
      preciosDetallados: json['preciosDetallados'],
      fuente: json['fuente'],
      direccion: json['direccion'],
      
      // Validamos que la lista de imágenes no venga nula antes de iterarla
      imagenes: json['imagenes'] != null
          ? (json['imagenes'] as List).map((i) => Imagen.fromJson(i)).toList()
          : [],
    );
  }
}