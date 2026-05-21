import 'package:choco/core/services/api_client.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:choco/features/actividades/models/actividad_exploracion.dart';

/// Servicio de actividades conectado al backend Spring Boot.
///
/// Endpoints consumidos:
///   GET /actividades/si         → List<Actividad>
///   GET /actividades/{id}       → Actividad por id
class ActividadesService {
  const ActividadesService({ApiClient? client}) : _client = client ?? const ApiClient();

  final ApiClient _client;

  bool get _backendConfigurado => _client.configurado;

  Future<List<ActividadExploracion>> getActividades({
    String? destinoKey,
    int? grupoViajeId,
    int? usuarioId,
    List<int>? categoriaIds,
    List<String>? categorias,
    bool usarPreferenciasPerfil = false,
  }) async {
    if (!_backendConfigurado) return const [];

    final requiereFiltroBackend = grupoViajeId != null ||
        usuarioId != null ||
        usarPreferenciasPerfil ||
        (categoriaIds != null && categoriaIds.isNotEmpty) ||
        (categorias != null && categorias.isNotEmpty);

    final raw = requiereFiltroBackend
        ? await _client.get(_swipePath(
            destinoKey: destinoKey,
            grupoViajeId: grupoViajeId,
            usuarioId: usuarioId,
            categoriaIds: categoriaIds,
            categorias: categorias,
            usarPreferenciasPerfil: usarPreferenciasPerfil,
          ))
        : await _client.get('/actividades/si');
    final list = raw as List<dynamic>;

    final actividades = list
        .map((e) => _fromBackJson(Map<String, dynamic>.from(e as Map)))
        .whereType<ActividadExploracion>()
        .toList();

    final key = destinoKey?.trim().toLowerCase();
    if (requiereFiltroBackend || key == null || key.isEmpty) return actividades;
    final filtered = actividades.where((a) => a.destinoKey == key).toList();
    return filtered.isNotEmpty ? filtered : actividades;
  }

  Future<void> confirmarExploracionIndividual({
    required int grupoViajeId,
    required int usuarioId,
    required List<String> actividadesInteresIds,
  }) async {
    if (!_backendConfigurado) return;
    await _client.post('/grupos/$grupoViajeId/exploracion-grupal/confirmar', {
      'usuarioId': usuarioId,
      'actividadesInteresIds': actividadesInteresIds,
    });
  }

  String _swipePath({
    String? destinoKey,
    int? grupoViajeId,
    int? usuarioId,
    List<int>? categoriaIds,
    List<String>? categorias,
    bool usarPreferenciasPerfil = false,
  }) {
    final partes = <String>[];
    void add(String key, Object? value) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) return;
      partes.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(raw)}');
    }

    add('destinoKey', destinoKey);
    add('grupoViajeId', grupoViajeId);
    add('usuarioId', usuarioId);
    if (usarPreferenciasPerfil) add('usarPreferenciasPerfil', true);
    if (categoriaIds != null) {
      for (final id in categoriaIds) {
        add('categoriaIds', id);
      }
    }
    if (categorias != null) {
      for (final categoria in categorias) {
        add('categorias', categoria);
      }
    }
    final query = partes.join('&');
    return query.isEmpty ? '/actividades/swipe' : '/actividades/swipe?$query';
  }

  Future<ActividadExploracion?> getActividadById(int id) async {
    if (!_backendConfigurado) return null;
    final data = await _client.get('/actividades/$id') as Map<String, dynamic>;
    return _fromBackJson(Map<String, dynamic>.from(data));
  }

  ActividadExploracion? _fromBackJson(Map<String, dynamic> j) {
    try {
      final id = '${j['id']}';
      final nombre = j['nombre'] as String? ?? 'Actividad';
      final descripcion = j['descripcion'] as String? ?? '';
      final costo = _toD(j['costoPorPersona']);
      final duracionMin = _toInt(j['duracionMin'], fallback: 120);
      final rating = _toD(j['calificacionPromedio']);
      final fuente = j['fuente'] as String? ?? '';

      final ciudadMap = j['ciudad'] is Map ? Map<String, dynamic>.from(j['ciudad'] as Map) : null;
      final ciudadNombre = ciudadMap?['nombre'] as String? ?? '';
      final pais = ciudadMap?['pais'] as String? ?? 'Colombia';

      final ubicacionMap = j['ubicacion'] is Map ? Map<String, dynamic>.from(j['ubicacion'] as Map) : null;
      final direccion = ubicacionMap?['direccion'] as String? ?? '';
      final ubicacionNombre = ubicacionMap?['nombre'] as String? ?? '';

      final destinoKey = _inferirDestinoKey('$ciudadNombre $direccion $ubicacionNombre $nombre');
      final destinoNombre = ciudadNombre.isNotEmpty ? ciudadNombre : _toTitleCase(destinoKey.replaceAll('_', ' '));

      final imagenesRaw = j['imagenes'] as List<dynamic>? ?? [];
      var imagenUrl = j['imagenUrl'] as String? ?? '';
      if (imagenUrl.isEmpty && imagenesRaw.isNotEmpty) {
        final first = Map<String, dynamic>.from(imagenesRaw.first as Map);
        imagenUrl = first['url'] as String? ?? '';
      }
      imagenUrl = resolveBackendAssetUrl(imagenUrl) ?? imagenUrl;

      final categoriasRaw = j['categorias'] as List<dynamic>? ?? [];
      final categorias = categoriasRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)['nombre'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      final categoria = categorias.isNotEmpty ? categorias.first : 'Experiencia local';

      return ActividadExploracion(
        id: id,
        nombre: nombre,
        destinoKey: destinoKey,
        destinoNombre: destinoNombre,
        categoria: categoria,
        tags: categorias.isNotEmpty ? categorias : [categoria, destinoKey],
        precioEstimado: costo,
        duracion: _duracionTexto(duracionMin),
        horarioSugerido: 'Flexible',
        ubicacionTexto: direccion.isNotEmpty ? direccion : (ubicacionNombre.isNotEmpty ? ubicacionNombre : '$destinoNombre, $pais'),
        descripcionCorta: descripcion.length > 140 ? '${descripcion.substring(0, 140)}…' : descripcion,
        descripcionLarga: descripcion.isNotEmpty ? descripcion : 'Plan recomendado por Choco para este destino.',
        imagenAssetPath: imagenUrl,
        rating: rating > 0 ? rating : 4.2,
        popularidad: 70,
        intensidad: _inferirIntensidad(categoria),
        aptoPara: const ['Grupo de amigos', 'Pareja', 'Familia con niños mayores'],
        presupuestoNivel: costo < 50000 ? 'bajo' : costo < 150000 ? 'medio' : 'alto',
        momentoDelDia: 'flexible',
        incluye: const ['Experiencia local', 'Tiempo para fotos'],
        recomendacionesChoco: 'Confirma punto de encuentro, clima y disponibilidad antes de salir.',
        accesibilidadNota: fuente.isNotEmpty ? 'Fuente: $fuente.' : 'Consulta condiciones de accesibilidad con el operador local.',
      );
    } catch (_) {
      return null;
    }
  }

  static String _duracionTexto(int minutos) {
    if (minutos <= 0) return 'Flexible';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  static int _inferirIntensidad(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('naturaleza') || c.contains('aventura') || c.contains('amazon')) return 4;
    if (c.contains('vida nocturna')) return 3;
    if (c.contains('relax') || c.contains('cultura')) return 1;
    return 2;
  }

  static int _toInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double _toD(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  static String _inferirDestinoKey(String texto) {
    final lower = texto.toLowerCase();
    const ciudades = {
      'cartagena': 'cartagena',
      'medellin': 'medellin',
      'medellín': 'medellin',
      'bogota': 'bogota',
      'bogotá': 'bogota',
      'cali': 'cali',
      'amazonas': 'amazonas',
    };
    for (final entry in ciudades.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'cartagena';
  }

  static String _toTitleCase(String s) {
    return s
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
