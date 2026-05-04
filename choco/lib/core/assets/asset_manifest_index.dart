import 'dart:convert';

import 'package:choco/core/assets/app_asset_registry.dart';
import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/core/assets/known_bundled_asset_paths.dart';
import 'package:flutter/services.dart';

/// Carga una sola vez las rutas del manifiesto de assets (sin asumir extensiones).
///
/// En **Flutter Web** el manifiesto ya no es `AssetManifest.json`; se usa
/// [AssetManifest.loadFromAssetBundle] (bin/json interno). Si falla, se hace
/// fallback a [kKnownBundledAssetPaths] para que la app no se rompa.
class AssetManifestIndex {
  AssetManifestIndex._(this.paths);

  final Set<String> paths;

  static AssetManifestIndex? _cached;

  static Future<AssetManifestIndex> load() async {
    if (_cached != null) return _cached!;
    final keys = <String>{};

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      keys.addAll(manifest.listAssets());
    } catch (_) {
      try {
        final raw = await rootBundle.loadString('AssetManifest.json');
        final map = jsonDecode(raw) as Map<String, dynamic>;
        keys.addAll(map.keys.cast<String>());
      } catch (_) {
        // Ignorar: usamos solo registro local.
      }
    }

    keys.addAll(kKnownBundledAssetPaths);
    keys.addAll(bundledPathsFromActividadYDestinoRegistry());
    _cached = AssetManifestIndex._(keys.map(normalizeFlutterAssetKey).toSet());
    return _cached!;
  }

  /// Solo tests / hot-reload de assets.
  static void clearCache() => _cached = null;

  Iterable<String> underPrefix(String prefix) {
    final p = prefix.endsWith('/') ? prefix : '$prefix/';
    return paths.where((e) => e.startsWith(p));
  }
}

bool esRutaImagenAsset(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.avif');
}
