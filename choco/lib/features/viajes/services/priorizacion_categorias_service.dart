import 'package:choco/core/services/api_client.dart';

class CategoriaPriorizacionModel {
  final int categoriaId;
  final String nombre;
  final String? descripcion;
  final int cantidadActividadesSeleccionadas;
  final int? posicionActual;
  final int? puntajeActual;

  const CategoriaPriorizacionModel({
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    required this.cantidadActividadesSeleccionadas,
    this.posicionActual,
    this.puntajeActual,
  });

  factory CategoriaPriorizacionModel.fromJson(Map<String, dynamic> json) {
    return CategoriaPriorizacionModel(
      categoriaId: (json['categoriaId'] as num).toInt(),
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion'] as String?,
      cantidadActividadesSeleccionadas:
          (json['cantidadActividadesSeleccionadas'] as num?)?.toInt() ?? 0,
      posicionActual: (json['posicionActual'] as num?)?.toInt(),
      puntajeActual: (json['puntajeActual'] as num?)?.toInt(),
    );
  }
}

class PriorizacionCategoriasEstado {
  final List<CategoriaPriorizacionModel> categoriasDisponibles;
  final int totalParticipantes;
  final int participantesPriorizados;
  final int faltanPorPriorizar;
  final bool listoParaItinerario;
  final bool usuarioActualPriorizo;
  final bool usuarioActualDebePriorizar;
  final bool usuarioActualPuedePriorizar;
  final String mensaje;

  const PriorizacionCategoriasEstado({
    required this.categoriasDisponibles,
    required this.totalParticipantes,
    required this.participantesPriorizados,
    required this.faltanPorPriorizar,
    required this.listoParaItinerario,
    required this.usuarioActualPriorizo,
    required this.usuarioActualDebePriorizar,
    required this.usuarioActualPuedePriorizar,
    required this.mensaje,
  });

  factory PriorizacionCategoriasEstado.fromJson(Map<String, dynamic> data) {
    final raw = (data['categoriasDisponibles'] as List<dynamic>? ?? const []);
    return PriorizacionCategoriasEstado(
      categoriasDisponibles: raw
          .map((e) => CategoriaPriorizacionModel.fromJson(e as Map<String, dynamic>))
          .where((c) => c.nombre.trim().isNotEmpty)
          .toList(),
      totalParticipantes: (data['totalParticipantes'] as num?)?.toInt() ?? 0,
      participantesPriorizados: (data['participantesPriorizados'] as num?)?.toInt() ?? 0,
      faltanPorPriorizar: (data['faltanPorPriorizar'] as num?)?.toInt() ?? 0,
      listoParaItinerario: data['listoParaItinerario'] == true,
      usuarioActualPriorizo: data['usuarioActualPriorizo'] == true || data['tienePriorizacion'] == true,
      usuarioActualDebePriorizar: data['usuarioActualDebePriorizar'] == true,
      usuarioActualPuedePriorizar: data['usuarioActualPuedePriorizar'] == true,
      mensaje: (data['mensaje'] as String?) ?? '',
    );
  }
}

class PriorizacionCategoriasService {
  const PriorizacionCategoriasService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  bool get backendConfigurado => _client.configurado;

  Future<PriorizacionCategoriasEstado?> cargarEstado({
    required int grupoViajeId,
    int? usuarioId,
  }) async {
    if (!backendConfigurado) return null;

    final query = usuarioId == null ? '' : '?usuarioId=$usuarioId';
    final data = await _client.get('/grupos/$grupoViajeId/priorizacion-categorias$query')
        as Map<String, dynamic>;
    return PriorizacionCategoriasEstado.fromJson(data);
  }

  Future<List<CategoriaPriorizacionModel>> cargarCategoriasDisponibles({
    required int grupoViajeId,
    int? usuarioId,
  }) async {
    final estado = await cargarEstado(grupoViajeId: grupoViajeId, usuarioId: usuarioId);
    return estado?.categoriasDisponibles ?? const [];
  }

  Future<void> guardarRanking({
    required int grupoViajeId,
    required List<String> categoriasOrdenadas,
    int? usuarioId,
  }) async {
    if (!backendConfigurado) return;
    await _client.post('/grupos/$grupoViajeId/priorizacion-categorias', {
      if (usuarioId != null) 'usuarioId': usuarioId,
      'categorias': categoriasOrdenadas,
    });
  }
}
