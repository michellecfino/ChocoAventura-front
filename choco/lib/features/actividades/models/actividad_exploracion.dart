/// Actividad enriquecida para exploración / swipe (datos locales, sin APIs).
class ActividadExploracion {
  final String id;
  final String nombre;
  final String destinoKey;
  final String destinoNombre;
  final String categoria;
  final List<String> tags;
  final double precioEstimado;
  final String moneda;
  final String duracion;
  final String horarioSugerido;
  final String ubicacionTexto;
  final String descripcionCorta;
  final String descripcionLarga;
  /// Ruta exacta en el bundle (desde AssetManifest).
  final String imagenAssetPath;
  final double rating;
  final int popularidad;
  /// 1 suave … 5 intenso
  final int intensidad;
  final List<String> aptoPara;
  final String presupuestoNivel;
  final String momentoDelDia;
  final double? latitudMock;
  final double? longitudMock;
  final List<String> incluye;
  final String recomendacionesChoco;
  final String accesibilidadNota;

  const ActividadExploracion({
    required this.id,
    required this.nombre,
    required this.destinoKey,
    required this.destinoNombre,
    required this.categoria,
    required this.tags,
    required this.precioEstimado,
    this.moneda = 'COP',
    required this.duracion,
    required this.horarioSugerido,
    required this.ubicacionTexto,
    required this.descripcionCorta,
    required this.descripcionLarga,
    required this.imagenAssetPath,
    required this.rating,
    required this.popularidad,
    required this.intensidad,
    required this.aptoPara,
    required this.presupuestoNivel,
    required this.momentoDelDia,
    this.latitudMock,
    this.longitudMock,
    required this.incluye,
    required this.recomendacionesChoco,
    required this.accesibilidadNota,
  });
}
