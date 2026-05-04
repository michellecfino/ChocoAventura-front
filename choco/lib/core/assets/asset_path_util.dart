/// Normaliza claves de asset para Web / bundle (evita prefijos duplicados).
///
/// Convención del proyecto: rutas tipo `assets/destinos/...`, `assets/choco/...`.
/// Si algo legacy produce `assets/assets/...` o `assets/lib/assets/...`, se corrige aquí.
String normalizeFlutterAssetKey(String raw) {
  var p = raw.trim();
  if (p.isEmpty) return p;
  while (p.startsWith('assets/assets/')) {
    p = p.substring('assets/'.length);
  }
  if (p.startsWith('assets/lib/assets/')) {
    p = p.substring('assets/lib/'.length);
  }
  if (p.startsWith('assets/lib/')) {
    p = p.substring('assets/'.length);
  }
  return p;
}
