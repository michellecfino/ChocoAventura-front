import 'dart:math';

import 'package:choco/core/services/api_client.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:flutter/foundation.dart';

/// Claves de destino en minúsculas (contrato de la app).
const Set<String> kDestinosAppKeys = {
  'bogota',
  'medellin',
  'cartagena',
  'amazonas',
  'cali',
};

String carpetaActividadesParaDestino(String destinoKey) {
  final k = destinoKey.toLowerCase().trim();
  return kDestinosAppKeys.contains(k) ? k : '';
}

String carpetaDestinosParaDestino(String destinoKey) {
  final k = destinoKey.toLowerCase().trim();
  return kDestinosAppKeys.contains(k) ? k : 'default';
}

List<String> prefijosDestino(String destinoKey) => ['assets/destinos/${carpetaDestinosParaDestino(destinoKey)}/'];
List<String> prefijosActividades(String destinoKey) {
  final k = carpetaActividadesParaDestino(destinoKey);
  return k.isEmpty ? const [] : ['assets/actividades/$k/'];
}

String nombreLegibleDestino(String destinoKey) {
  switch (destinoKey.toLowerCase()) {
    case 'bogota':
      return 'Bogotá';
    case 'medellin':
      return 'Medellín';
    case 'cartagena':
      return 'Cartagena';
    case 'amazonas':
      return 'Amazonas';
    case 'cali':
      return 'Cali';
    default:
      return 'Colombia';
  }
}

class AssetResolver {
  AssetResolver._({
    required Map<String, List<String>> destinos,
    required Map<String, List<String>> actividades,
    required Map<String, List<String>> perfiles,
    required List<String> choco,
  })  : _destinos = destinos,
        _actividades = actividades,
        _perfiles = perfiles,
        _choco = choco;

  static AssetResolver? _instance;
  final Random _rnd = Random();
  final Map<String, List<String>> _reciente = {};

  final Map<String, List<String>> _destinos;
  final Map<String, List<String>> _actividades;
  final Map<String, List<String>> _perfiles;
  final List<String> _choco;

  static Future<AssetResolver> instance() async {
    if (_instance != null) return _instance!;
    _instance = await _fromBackendCatalog();
    return _instance!;
  }

  @visibleForTesting
  static void bindForTest(AssetResolver r) => _instance = r;

  static Future<AssetResolver> _fromBackendCatalog() async {
    const client = ApiClient();
    if (!client.configurado) {
      return AssetResolver._(
        destinos: const {},
        actividades: const {},
        perfiles: const {},
        choco: const [],
      );
    }
    try {
      final raw = await client.get('/assets-catalog') as Map<String, dynamic>;
      return AssetResolver._(
        destinos: _parseSection(raw['destinos']),
        actividades: _parseSection(raw['actividades']),
        perfiles: _parseSection(raw['perfiles']),
        choco: _parseList(raw['choco']),
      );
    } catch (_) {
      return AssetResolver._(
        destinos: const {},
        actividades: const {},
        perfiles: const {},
        choco: const [],
      );
    }
  }

  static Map<String, List<String>> _parseSection(dynamic value) {
    if (value is! Map) return const {};
    final out = <String, List<String>>{};
    value.forEach((key, list) {
      out['$key'.toLowerCase()] = _parseList(list);
    });
    return out;
  }

  static List<String> _parseList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => '$e').where((e) => e.trim().isNotEmpty).map(_fullUrl).toList();
  }

  static String _fullUrl(String value) => resolveBackendAssetUrl(value) ?? value;

  void _registrarUso(String claveLogica, String pathElegido) {
    final list = _reciente.putIfAbsent(claveLogica, () => []);
    list.remove(pathElegido);
    list.insert(0, pathElegido);
    while (list.length > 3) {
      list.removeLast();
    }
  }

  String? _elegir(List<String> pool, String claveLogica) {
    if (pool.isEmpty) return null;
    final evitar = _reciente[claveLogica] ?? const <String>[];
    final candidatos = pool.where((p) => !evitar.contains(p)).toList();
    final usar = candidatos.isNotEmpty ? candidatos : pool;
    final pick = usar[_rnd.nextInt(usar.length)];
    _registrarUso(claveLogica, pick);
    return pick;
  }

  List<String> _listarChoco() => [..._choco]..sort();

  String resolveChocoAvatar() {
    final all = _listarChoco();
    const preferidos = ['saludando.png', 'sonrie.png', 'choco_icon.png', 'logo.png'];
    for (final nombre in preferidos) {
      final found = all.where((p) => p.toLowerCase().endsWith('/$nombre')).toList();
      if (found.isNotEmpty) {
        _registrarUso('choco_avatar', found.first);
        return found.first;
      }
    }
    return _elegir(all, 'choco_avatar') ?? '';
  }

  String resolveChocoListening() {
    final all = _listarChoco();
    const preferidos = ['hablando.png', 'microfono.png', 'saludando.png'];
    for (final nombre in preferidos) {
      final found = all.where((p) => p.toLowerCase().endsWith('/$nombre')).toList();
      if (found.isNotEmpty) return found.first;
    }
    return resolveChocoAvatar();
  }

  List<String> listarImagenesDestino(String destinoKey) {
    final key = destinoKey.toLowerCase().trim();
    return [...(_destinos[key] ?? const <String>[])]..sort();
  }

  String resolveDestinoImage(String destinoKey) {
    final key = destinoKey.toLowerCase().trim();
    final pool = listarImagenesDestino(key);
    if (pool.isEmpty) return '';
    return _elegir(pool, 'destino|$key') ?? pool.first;
  }

  List<String> listarImagenesActividadCarpeta(String destinoKey) {
    final key = destinoKey.toLowerCase().trim();
    return [...(_actividades[key] ?? const <String>[])]..sort();
  }

  String resolveChocoNavLogo() {
    final all = _listarChoco();
    final logos = all.where((p) => p.toLowerCase().endsWith('/logo.png')).toList();
    if (logos.isNotEmpty) return logos.first;
    return resolveChocoAvatar();
  }

  String resolveChocoAssistant() => resolveChocoAvatar();
  String resolveChocoFallback() => resolveChocoNavLogo();

  String? resolveActividadImage({
    required String destinoKey,
    required String assetPathActividad,
  }) {
    final resolved = resolveBackendAssetUrl(assetPathActividad);
    if (resolved != null && resolved.isNotEmpty) return resolved;
    final pool = listarImagenesActividadCarpeta(destinoKey);
    if (pool.isEmpty) return resolveDestinoImage(destinoKey);
    return _elegir(pool, 'actividad|$destinoKey|$assetPathActividad') ?? pool.first;
  }

  List<String> listarPerfilesHombre() => [...(_perfiles['hombre'] ?? const <String>[])]..sort();
  List<String> listarPerfilesMujer() => [...(_perfiles['mujer'] ?? const <String>[])]..sort();

  String resolvePerfilImage({String? genero}) {
    final hombre = listarPerfilesHombre();
    final mujer = listarPerfilesMujer();
    List<String> pool;
    if (genero == 'm') {
      pool = mujer.isNotEmpty ? mujer : hombre;
    } else if (genero == 'h') {
      pool = hombre.isNotEmpty ? hombre : mujer;
    } else {
      pool = [...hombre, ...mujer];
    }
    if (pool.isEmpty) {
      final placeholder = _perfiles['placeholder'] ?? const <String>[];
      return placeholder.isNotEmpty ? placeholder.first : resolveChocoAvatar();
    }
    return _elegir(pool, 'perfil|${genero ?? 'x'}') ?? pool.first;
  }
}
