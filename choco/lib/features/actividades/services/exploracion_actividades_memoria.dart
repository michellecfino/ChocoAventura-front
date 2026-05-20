/// Preferencias de swipe en memoria (sesión). Luego puede persistirse / backend.
class ExploracionActividadesMemoria {
  ExploracionActividadesMemoria._();

  static final Map<String, Set<String>> _meInteresa = {};
  static final Map<String, Set<String>> _paso = {};

  static String claveSesion({String? viajeId, required String destinoKey}) =>
      '${viajeId ?? 'sin_viaje'}|${destinoKey.toLowerCase()}';

  static Set<String> meInteresaIds(String clave) => _meInteresa.putIfAbsent(clave, () => {});

  static Set<String> pasoIds(String clave) => _paso.putIfAbsent(clave, () => {});

  static void registrarInteres(String clave, String actividadId) {
    meInteresaIds(clave).add(actividadId);
    pasoIds(clave).remove(actividadId);
  }

  static void registrarPaso(String clave, String actividadId) {
    pasoIds(clave).add(actividadId);
    meInteresaIds(clave).remove(actividadId);
  }
}
