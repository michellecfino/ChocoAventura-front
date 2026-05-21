// Escanea la carpeta raíz `assets/` y escribe app_asset_registry.dart (sin renombrar archivos).
// Uso: dart run tool/build_registry_only.dart

import 'dart:io';

const _destinosKeys = ['amazonas', 'bogota', 'cali', 'cartagena', 'medellin'];

String _basenameP(String path) {
  final norm = path.replaceAll('/', Platform.pathSeparator);
  final i = norm.lastIndexOf(Platform.pathSeparator);
  return i < 0 ? norm : norm.substring(i + 1);
}

bool _esImagen(String n) {
  final l = n.toLowerCase();
  return l.endsWith('.jpg') ||
      l.endsWith('.jpeg') ||
      l.endsWith('.png') ||
      l.endsWith('.webp') ||
      l.endsWith('.avif');
}

List<String> _listarRelativos(Directory dir, String prefixUrl) {
  if (!dir.existsSync()) return [];
  final out = <String>[];
  for (final f in dir.listSync()) {
    if (f is! File || f.path.endsWith('.py')) continue;
    final n = f.uri.pathSegments.last;
    if (!_esImagen(n)) continue;
    out.add('$prefixUrl$n');
  }
  out.sort();
  return out;
}

/// Carpetas reales de actividades → destinoKey (Windows puede normalizar mayúsculas).
String? _carpetaActividadAKey(String carpeta) {
  switch (carpeta.toLowerCase()) {
    case 'amazonas':
      return 'amazonas';
    case 'bogota':
      return 'bogota';
    case 'cali':
      return 'cali';
    case 'cartagena':
      return 'cartagena';
    case 'medellin':
      return 'medellin';
    default:
      return null;
  }
}

void main() {
  final sep = Platform.pathSeparator;
  final buf = StringBuffer()
    ..writeln('// Generado por tool/build_registry_only.dart desde el disco local.')
    ..writeln()
    ..writeln('const Map<String, List<String>> kDestinoImagenesPorDestino = {');

  for (final key in _destinosKeys) {
    final dir = Directory('assets${sep}destinos${sep}$key');
    final paths = _listarRelativos(dir, 'assets/destinos/$key/');
    buf.writeln("  '$key': [");
    for (final p in paths) {
      buf.writeln("    '$p',");
    }
    buf.writeln('  ],');
  }
  buf.writeln('};');
  buf.writeln();
  buf.writeln('/// Rutas reales bajo assets/actividades/{carpeta}/ tal como están en disco.');
  buf.writeln('const Map<String, List<String>> kActividadImagenesPorDestino = {');

  final actRoot = Directory('assets${sep}actividades');
  final porKey = <String, List<String>>{
    for (final k in _destinosKeys) k: <String>[],
  };

  if (actRoot.existsSync()) {
    for (final e in actRoot.listSync()) {
      if (e is! Directory) continue;
      final carpetaReal = _basenameP(e.path);
      final key = _carpetaActividadAKey(carpetaReal);
      if (key == null) continue;
      for (final f in e.listSync()) {
        if (f is! File || f.path.endsWith('.py')) continue;
        final n = _basenameP(f.path);
        if (!_esImagen(n)) continue;
        porKey[key]!.add('assets/actividades/$carpetaReal/$n');
      }
      porKey[key]!.sort();
    }
  }

  for (final key in _destinosKeys) {
    buf.writeln("  '$key': [");
    for (final p in porKey[key]!) {
      buf.writeln("    '${p.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}',");
    }
    buf.writeln('  ],');
  }
  buf.writeln('};');
  buf.writeln();
  buf.writeln('Set<String> bundledPathsFromActividadYDestinoRegistry() {');
  buf.writeln('  final o = <String>{};');
  buf.writeln('  for (final e in kDestinoImagenesPorDestino.values) { o.addAll(e); }');
  buf.writeln('  for (final e in kActividadImagenesPorDestino.values) { o.addAll(e); }');
  buf.writeln('  return o;');
  buf.writeln('}');

  File('lib/core/assets/app_asset_registry.dart').writeAsStringSync(buf.toString());
  stdout.writeln('Escrito lib/core/assets/app_asset_registry.dart');
}
