import 'package:choco/core/assets/asset_path_util.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/features/actividades/models/actividad_exploracion.dart';

String _baseNombreArchivo(String assetPath) {
  final name = assetPath.split('/').last;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// Convierte nombre de archivo a título legible (respeta espacios ya humanos).
String nombreActividadDesdeArchivo(String assetPath) {
  final base = _baseNombreArchivo(assetPath);
  if (base.contains(' ')) {
    return base.trim();
  }
  final parts = base.split('_').where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return base;
  return parts.map((w) {
    if (w.isEmpty) return '';
    final lower = w.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

String _joinTags(List<String> t) => t.take(6).join(', ');

({String categoria, List<String> tags, int intensidad, String presupuesto, String momento})
    _inferirMetadata(String nombreLower, String destinoKey) {
  final tags = <String>[];
  var categoria = 'Experiencia local';
  var intensidad = 2;
  var presupuesto = 'medio';
  var momento = 'flexible';

  void tag(String t) {
    if (!tags.contains(t)) tags.add(t);
  }

  if (RegExp(r'playa|mar|kayak|buceo|snorkel|paddle|bar[uú]|island|snorkel').hasMatch(nombreLower)) {
    categoria = 'Mar y playa';
    tag('agua');
    intensidad = 2;
    momento = 'mañana o tarde';
  }
  if (RegExp(
          r'museo|historia|cultura|candelaria|colonial|muralla|plaza|centro hist|centro histórico|ciudad amurallada|getseman|botero|oro|teatro')
      .hasMatch(nombreLower)) {
    categoria = 'Cultura e historia';
    tag('cultura');
    intensidad = 1;
  }
  if (RegExp(r'comida|gastro|restaurante|cata|chocolate|caf[eé]|mercado|cholado|lulada|vallun|brunch|cena|degustaci')
      .hasMatch(nombreLower)) {
    categoria = 'Gastronomía';
    tag('comida');
    presupuesto = 'medio-alto';
    momento = 'almuerzo o cena';
  }
  if (RegExp(r'senderismo|camina|cascada|cerro|naturaleza|selva|canopy|puentes|fauna|sendero|bosque|farallones')
      .hasMatch(nombreLower)) {
    categoria = 'Naturaleza y aventura';
    tag('aire libre');
    intensidad = 4;
    presupuesto = 'medio';
  }
  if (RegExp(r'baile|salsa|champeta|discoteca|m[uú]sica en vivo|show|noche|leyendas nocturn').hasMatch(nombreLower)) {
    categoria = 'Vida nocturna';
    tag('fiesta');
    momento = 'noche';
    intensidad = 3;
  }
  if (RegExp(r'spa|relax|picnic|atardecer tranquilo|descans').hasMatch(nombreLower)) {
    categoria = 'Relax';
    tag('relax');
    intensidad = 1;
    momento = 'tarde';
  }
  if (RegExp(r'tour|excursi[oó]n|excursion|ruta gui|metrocable|pueblo cercano').hasMatch(nombreLower)) {
    if (categoria == 'Experiencia local') categoria = 'Experiencias auténticas';
    tag('tour');
  }
  if (RegExp(r'comunidad|ind[ií]gena|transformaci[oó]n|metrocable|graffiti|comuna').hasMatch(nombreLower)) {
    categoria = 'Experiencias auténticas';
    tag('comunidad');
  }
  if (RegExp(r'amazonas|r[ií]o|delf|selva|canoa|lancha').hasMatch(nombreLower) || destinoKey == 'amazonas') {
    tag('naturaleza');
    if (categoria == 'Experiencia local') categoria = 'Amazonía';
  }

  tag(destinoKey);
  if (tags.length < 3) {
    tag('en grupo');
    tag('fotos');
  }

  return (categoria: categoria, tags: tags, intensidad: intensidad, presupuesto: presupuesto, momento: momento);
}

double _precioSugerido(String categoria, int popularidad) {
  var base = 45000.0;
  if (categoria.contains('Gastronomía')) base = 65000;
  if (categoria.contains('Mar')) base = 90000;
  if (categoria.contains('Naturaleza')) base = 75000;
  if (categoria.contains('Amazonía')) base = 120000;
  base += popularidad * 2500;
  return (base / 1000).round() * 1000.0;
}

/// Construye actividades desde rutas reales del manifiesto (una por imagen).
List<ActividadExploracion> construirActividadesDesdeAssets({
  required String destinoKey,
  required List<String> rutasImagenesOrdenadas,
}) {
  final destinoNombre = nombreLegibleDestino(destinoKey);
  final out = <ActividadExploracion>[];
  var i = 0;
  for (final path in rutasImagenesOrdenadas) {
    i++;
    final nombre = nombreActividadDesdeArchivo(path);
    final nombreLower = nombre.toLowerCase();
    final meta = _inferirMetadata(nombreLower, destinoKey);
    final popularidad = 60 + (i * 7) % 35;
    final rating = 4.0 + (popularidad % 9) * 0.08;
    final precio = _precioSugerido(meta.categoria, popularidad % 10);

    final descripcionCorta =
        'Plan en $destinoNombre para disfrutar «$nombre» con buen ritmo y seguridad. Ideal para sumarlo al itinerario del grupo.';
    final descripcionLarga =
        '$nombre es una propuesta $destinoNombre que suele gustar a grupos mixtos: combina ${meta.categoria.toLowerCase()} con tiempo para fotos y descansos. '
        'Choco sugiere reservar con margen de tiempo y confirmar el punto de encuentro con anticipación.';

    out.add(
      ActividadExploracion(
        id: '$destinoKey-${_baseNombreArchivo(path)}-$i',
        nombre: nombre,
        destinoKey: destinoKey,
        destinoNombre: destinoNombre,
        categoria: meta.categoria,
        tags: meta.tags,
        precioEstimado: precio,
        moneda: 'COP',
        duracion: meta.intensidad >= 4 ? '3 a 6 horas' : '2 a 4 horas',
        horarioSugerido: meta.momento == 'noche' ? '19:00 – 23:00' : '09:00 – 14:00',
        ubicacionTexto: 'Zona típica de $destinoNombre (referencia general; sin mapa en esta versión).',
        descripcionCorta: descripcionCorta,
        descripcionLarga: descripcionLarga,
        imagenAssetPath: normalizeFlutterAssetKey(path),
        rating: double.parse(rating.toStringAsFixed(1)),
        popularidad: popularidad,
        intensidad: meta.intensidad.clamp(1, 5),
        aptoPara: const ['Grupo de amigos', 'Pareja', 'Familia con niños mayores'],
        presupuestoNivel: meta.presupuesto,
        momentoDelDia: meta.momento,
        latitudMock: null,
        longitudMock: null,
        incluye: [
          'Guía o experiencia autoguiada (según el lugar)',
          'Tiempo para fotos',
          if (meta.categoria.contains('Gastronomía')) 'Degustación o comida típica (referencia)',
        ],
        recomendacionesChoco:
            'Lleva hidratación, bloqueador si es al aire libre y avisa al grupo el punto de encuentro. Si llueve, ten plan B cercano.',
        accesibilidadNota:
            'La accesibilidad depende del operador local; pregunta por rampas o sillas si alguien del grupo lo necesita.',
      ),
    );
  }
  return out;
}

/// Mezcla 60% alineadas a intereses, 25% populares, 15% sorpresa (heurística sin duplicar).
List<ActividadExploracion> mezclarDeckActividades({
  required List<ActividadExploracion> todas,
  List<String>? interesesUsuario,
  int limiteInicial = 40,
}) {
  if (todas.isEmpty) return const [];

  final limiteSeguro = limiteInicial.clamp(1, todas.length);

  final intereses = (interesesUsuario ?? const <String>[])
      .map((e) => e.toLowerCase().trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool matchea(ActividadExploracion a) {
    if (intereses.isEmpty) return false;
    final blob = '${a.nombre} ${a.categoria} ${_joinTags(a.tags)}'.toLowerCase();
    for (final t in intereses) {
      if (blob.contains(t)) return true;
    }
    return false;
  }

  final alineadas = todas.where(matchea).toList();
  final populares = [...todas]..sort((a, b) => b.popularidad.compareTo(a.popularidad));
  final sorpresa = [...todas]..shuffle();

  final seen = <String>{};
  void addUnique(ActividadExploracion a, List<ActividadExploracion> bucket) {
    if (seen.add(a.id)) bucket.add(a);
  }

  final objetivo = limiteSeguro;
  final nA = (objetivo * 0.6).round();
  final nP = (objetivo * 0.25).round();
  final nS = objetivo - nA - nP;

  final deck = <ActividadExploracion>[];
  var ia = 0, ip = 0, iss = 0;

  while (deck.length < objetivo && deck.length < todas.length) {
    if (ia < nA && ia < alineadas.length) {
      addUnique(alineadas[ia++], deck);
      continue;
    }
    if (ip < nP && ip < populares.length) {
      addUnique(populares[ip++], deck);
      continue;
    }
    if (iss < nS && iss < sorpresa.length) {
      addUnique(sorpresa[iss++], deck);
      continue;
    }
    for (final a in todas) {
      addUnique(a, deck);
      if (deck.length >= objetivo) break;
    }
    break;
  }

  // Evitar que todas sean misma categoría: intercalar categorías distintas cuando se pueda
  deck.sort((a, b) => a.categoria.compareTo(b.categoria));
  final intercalado = <ActividadExploracion>[];
  final porCat = <String, List<ActividadExploracion>>{};
  for (final a in deck) {
    porCat.putIfAbsent(a.categoria, () => []).add(a);
  }
  while (porCat.values.any((l) => l.isNotEmpty)) {
    for (final e in porCat.entries.toList()..sort((x, y) => y.value.length.compareTo(x.value.length))) {
      if (e.value.isEmpty) continue;
      intercalado.add(e.value.removeAt(0));
    }
  }

  return intercalado;
}
