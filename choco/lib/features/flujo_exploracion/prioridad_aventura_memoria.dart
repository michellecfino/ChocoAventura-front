/// Orden de categorías elegidas por el usuario (hasta 5) para desempates en Mesa / itinerario.
class PrioridadAventuraMemoria {
  PrioridadAventuraMemoria._();

  static final Map<String, List<String>> _ordenPorClave = {};

  static String clave({String? viajeId, required String destinoKey}) =>
      '${viajeId ?? 'sin_viaje'}|${destinoKey.toLowerCase().trim()}';

  static List<String>? leerOrden(String clave) {
    final v = _ordenPorClave[clave];
    if (v == null || v.isEmpty) return null;
    return List<String>.from(v);
  }

  static void guardar(String clave, List<String> orden) {
    _ordenPorClave[clave] = List<String>.from(orden);
  }
}
