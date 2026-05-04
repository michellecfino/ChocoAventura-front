import 'dart:math';

import 'package:choco/core/assets/app_asset_registry.dart';
import 'package:choco/core/assets/asset_manifest_index.dart';
import 'package:choco/core/assets/known_bundled_asset_paths.dart';
import 'package:flutter/foundation.dart';

/// Claves de destino en minúsculas (contrato de la app).
const Set<String> kDestinosAppKeys = {
  'bogota',
  'medellin',
  'cartagena',
  'amazonas',
  'cali',
};

/// Subcarpeta bajo `assets/actividades/` (misma clave que destino; vacío si no hay fotos).
String carpetaActividadesParaDestino(String destinoKey) {
  return kCarpetaActividadesPorDestino[destinoKey.toLowerCase().trim()] ?? '';
}

String carpetaDestinosParaDestino(String destinoKey) {
  final k = destinoKey.toLowerCase();
  if (k.isEmpty || !kDestinosAppKeys.contains(k)) return 'default';
  return k;
}

/// Rutas de banner: solo `assets/destinos/{destinoKey}/` (minúsculas).
List<String> prefijosDestino(String destinoKey) {
  final k = carpetaDestinosParaDestino(destinoKey);
  return ['assets/destinos/$k/'];
}

List<String> prefijosActividades(String destinoKey) {
  final k = destinoKey.toLowerCase().trim();
  final folder = carpetaActividadesParaDestino(k);
  if (folder.isEmpty) return const [];
  return ['assets/actividades/$folder/'];
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

/// Resolución centralizada de imágenes con rotación (evita repetir la última y prioriza últimas 3).
class AssetResolver {
  AssetResolver._(this._index);

  final AssetManifestIndex _index;
  static AssetResolver? _instance;

  final Random _rnd = Random();

  /// Reciente por clave lógica (destino, actividadId, perfil, choco).
  final Map<String, List<String>> _reciente = {};

  static Future<AssetResolver> instance() async {
    if (_instance != null) return _instance!;
    final idx = await AssetManifestIndex.load();
    _instance = AssetResolver._(idx);
    return _instance!;
  }

  @visibleForTesting
  static void bindForTest(AssetResolver r) => _instance = r;

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

  List<String> _listarChoco() {
    return _index.underPrefix('assets/choco/').where(esRutaImagenAsset).toList()..sort();
  }

  /// Imagen principal de Choco (avatar / navbar).
  String resolveChocoAvatar() {
    final all = _listarChoco();
    const preferidos = [
      'assets/choco/saludando.png',
      'assets/choco/sonrie.png',
      'assets/choco/choco_icon.png',
      'assets/choco/logo.png',
    ];
    for (final p in preferidos) {
      if (all.contains(p)) {
        _registrarUso('choco_avatar', p);
        return p;
      }
    }
    return _elegir(all, 'choco_avatar') ?? 'assets/perfiles/placeholder.png';
  }

  /// Variante mientras escucha (si existe en manifiesto).
  String resolveChocoListening() {
    final all = _listarChoco();
    const preferidos = [
      'assets/choco/hablando.png',
      'assets/choco/microfono.png',
      'assets/choco/saludando.png',
    ];
    for (final p in preferidos) {
      if (all.contains(p)) return p;
    }
    return resolveChocoAvatar();
  }

  List<String> listarImagenesDestino(String destinoKey) {
    final merged = <String>{};
    final dk = destinoKey.toLowerCase().trim();
    final reg = kDestinoImagenesPorDestino[dk];
    if (reg != null) merged.addAll(reg);
    for (final p in prefijosDestino(destinoKey)) {
      merged.addAll(_index.underPrefix(p).where(esRutaImagenAsset));
    }
    merged.addAll(knownDestinoImagePathsForKey(destinoKey));
    if (merged.isEmpty) {
      for (final p in const ['assets/destinos/default/']) {
        merged.addAll(_index.underPrefix(p).where(esRutaImagenAsset));
      }
    }
    return merged.toList()..sort();
  }

  /// Banner de viaje: solo fotos del destino (nunca Choco como banner).
  String resolveDestinoImage(String destinoKey) {
    final pool = listarImagenesDestino(destinoKey).where((p) => !p.contains('/choco/')).toList();
    final k = destinoKey.toLowerCase();
    if (pool.isEmpty) {
      final any = knownAnyDestinoImagePaths();
      if (any.isNotEmpty) {
        return _elegir(any, 'destino|fallback|$k') ?? any.first;
      }
      return 'assets/perfiles/placeholder.png';
    }
    return _elegir(pool, 'destino|$k') ?? pool.first;
  }

  List<String> listarImagenesActividadCarpeta(String destinoKey) {
    final merged = <String>{};
    final dk = destinoKey.toLowerCase().trim();
    final reg = kActividadImagenesPorDestino[dk];
    if (reg != null) merged.addAll(reg);
    for (final p in prefijosActividades(destinoKey)) {
      merged.addAll(
        _index.underPrefix(p).where(esRutaImagenAsset).where((x) => !x.toLowerCase().endsWith('.py')),
      );
    }
    merged.addAll(knownActividadImagePathsForKey(destinoKey));
    return merged.toList()..sort();
  }

  /// Logo fijo de la barra inferior: `assets/choco/logo.png` si está en bundle.
  String resolveChocoNavLogo() {
    const logo = 'assets/choco/logo.png';
    if (_index.paths.contains(logo)) return logo;
    for (final ext in const ['.webp', '.jpg', '.jpeg']) {
      final p = 'assets/choco/logo$ext';
      if (_index.paths.contains(p)) return p;
    }
    for (final path in _index.paths) {
      if (!path.startsWith('assets/choco/')) continue;
      final lower = path.toLowerCase();
      if (lower.contains('/logo.') && esRutaImagenAsset(path)) return path;
    }
    return resolveChocoAvatar();
  }

  String resolveChocoAssistant() => resolveChocoAvatar();

  String resolveChocoFallback() {
    const ph = 'assets/perfiles/placeholder.png';
    if (_index.paths.contains(ph)) return ph;
    return resolveChocoNavLogo();
  }

  /// Una imagen por actividad (nombre de archivo = actividad).
  String? resolveActividadImage({
    required String destinoKey,
    required String assetPathActividad,
  }) {
    final base = assetPathActividad.split('/').last;
    final clave = 'actividad|$destinoKey|$base';
    final folder = carpetaActividadesParaDestino(destinoKey);
    if (folder.isEmpty) return null;
    final stem = base.replaceAll(RegExp(r'\.[^.]+$'), '');
    final mismoStem = listarImagenesActividadCarpeta(destinoKey).where((p) {
      final f = p.split('/').last.replaceAll(RegExp(r'\.[^.]+$'), '');
      return f.toLowerCase() == stem.toLowerCase();
    }).toList();
    if (mismoStem.isNotEmpty) {
      return _elegir(mismoStem, clave);
    }
    if (_index.paths.contains(assetPathActividad)) return assetPathActividad;
    return resolveDestinoImage(destinoKey);
  }

  List<String> listarPerfilesHombre() =>
      _index.underPrefix('assets/perfiles/hombre/').where(esRutaImagenAsset).toList();

  List<String> listarPerfilesMujer() =>
      _index.underPrefix('assets/perfiles/mujer/').where(esRutaImagenAsset).toList();

  String resolvePerfilImage({String? genero}) {
    const ph = 'assets/perfiles/placeholder.png';
    if (_index.paths.contains(ph)) {
      // aún rotamos placeholder si es el único
    }
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
      return _index.paths.contains(ph) ? ph : resolveChocoAvatar();
    }
    return _elegir(pool, 'perfil|${genero ?? 'x'}') ?? pool.first;
  }
}
