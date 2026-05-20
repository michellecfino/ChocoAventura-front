import 'dart:math';

import 'package:choco/features/actividades/screens/explorar_actividades_swipe_screen.dart';
import 'package:choco/features/gastos/models/gastos_models.dart';
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intenciones locales (sin LLM obligatorio).
enum ChocoIntent {
  ayudaGeneral,
  crearViaje,
  registrarGasto,
  explorarActividades,
  itinerario,
  balancesDebo,
  balancesMeDeben,
  unirseViaje,
  mesaChoco,
  codigoInvitacion,
  estadoGrupoVoto,
  priorizarCategorias,
  fueraDeContexto,
}

class ChocoAction {
  final String id;
  final String etiqueta;
  final void Function(BuildContext context)? ejecutar;

  const ChocoAction({required this.id, required this.etiqueta, this.ejecutar});
}

class ChocoResponse {
  final String texto;
  final List<ChocoAction> acciones;
  final bool sugerirRevisionGasto;

  const ChocoResponse({
    required this.texto,
    this.acciones = const [],
    this.sugerirRevisionGasto = false,
  });
}

typedef NavegarNuevaAventuraCallback = void Function(BuildContext context);
typedef AbrirExplorarCallback = void Function(BuildContext context, String destinoKey);

/// Motor de intenciones y respuestas variables para ChocoAventura.
class ChocoAssistantService {
  ChocoAssistantService({Random? random}) : _rnd = random ?? Random();

  final Random _rnd;

  static const _fueraContexto =
      'Puedo ayudarte con viajes, gastos, itinerarios, actividades y preferencias de ChocoAventura. ¿Qué necesitas?';

  GrupoViajeModel? _viajePorMencion(String texto) {
    final x = texto.toLowerCase();
    for (final v in kViajesMockRicos) {
      if (x.contains(v.nombreViaje.toLowerCase())) return v;
    }
    return null;
  }

  GrupoViajeModel _viajePorDefecto() => kViajesMockRicos.isNotEmpty ? kViajesMockRicos.first : _viajeFallback();

  GrupoViajeModel _viajeFallback() => GrupoViajeModel(
        id: 1,
        nombreViaje: 'Tu aventura',
        destinoKey: 'cartagena',
        destinoNombre: 'Cartagena',
        ciudadDepartamento: 'Cartagena',
        participantes: 5,
        codigoInvitacion: 'CHOCO-DEMO',
        linkInvitacion: 'https://chocoaventura.app/i/DEMO',
      );

  ChocoIntent detectarIntent(String texto) {
    final x = texto.toLowerCase().trim();
    if (x.isEmpty) return ChocoIntent.ayudaGeneral;

    if (RegExp(r'\b(qu[eé] es|quien eres|buenas|hey)\b').hasMatch(x) && x.length < 40) {
      return ChocoIntent.ayudaGeneral;
    }
    if ((x.contains('crear') && x.contains('viaje')) || x.contains('nueva aventura') || x.contains('nuevo viaje')) {
      return ChocoIntent.crearViaje;
    }
    if (x.contains('mesa') && (x.contains('choco') || x.contains('consen'))) {
      return ChocoIntent.mesaChoco;
    }
    if (x.contains('prioriz') || x.contains('ingredientes') || x.contains('top 5')) {
      return ChocoIntent.priorizarCategorias;
    }
    if ((x.contains('código') || x.contains('codigo')) && x.contains('viaje')) {
      return ChocoIntent.codigoInvitacion;
    }
    if (x.contains('código') || x.contains('codigo') || x.contains('link de invit') || x.contains('invitación')) {
      return ChocoIntent.codigoInvitacion;
    }
    if (x.contains('vot') && (x.contains('grupo') || x.contains('termin') || x.contains('falta') || x.contains('listo'))) {
      return ChocoIntent.estadoGrupoVoto;
    }
    if (x.contains('unir') || x.contains('invitaci')) {
      return ChocoIntent.unirseViaje;
    }
    if (x.contains('actividad') || x.contains('explorar') || x.contains('planes') || x.contains('swipe') || x.contains('qué puedo hacer')) {
      return ChocoIntent.explorarActividades;
    }
    if (x.contains('itinerario') || x.contains('agenda') || x.contains('calendario')) {
      return ChocoIntent.itinerario;
    }
    if (x.contains('cuánto debo') || x.contains('cuanto debo') || RegExp(r'\bdebo\b').hasMatch(x)) {
      return ChocoIntent.balancesDebo;
    }
    if (x.contains('me deben') || x.contains('quién me debe') || x.contains('quien me debe')) {
      return ChocoIntent.balancesMeDeben;
    }
    if ((x.contains('registrar') && x.contains('gasto')) ||
        x.contains('taxi') ||
        x.contains('pagué') ||
        x.contains('pague') ||
        (RegExp(r'\d').hasMatch(x) && (x.contains('mil') || x.contains('peso') || x.contains('gasto')))) {
      return ChocoIntent.registrarGasto;
    }
    if (x.contains('clima') || x.contains('bitcoin') || x.contains('pol[ií]tic')) {
      return ChocoIntent.fueraDeContexto;
    }
    if (x.contains('gasto') || x.contains('balance') || x.contains('plata')) {
      return ChocoIntent.ayudaGeneral;
    }
    return ChocoIntent.ayudaGeneral;
  }

  String? _elegir(List<String> opciones) {
    if (opciones.isEmpty) return null;
    return opciones[_rnd.nextInt(opciones.length)];
  }

  ChocoResponse responder({
    required String textoUsuario,
    required NavegarNuevaAventuraCallback navegarNuevaAventura,
    required AbrirExplorarCallback abrirExplorar,
    required VoidCallback verGastos,
    required VoidCallback verItinerario,
    void Function(BuildContext ctx)? navegarMesaChoco,
    void Function(BuildContext ctx)? navegarPriorizar,
    void Function(BuildContext ctx)? abrirEstadoGrupo,
  }) {
    final intent = detectarIntent(textoUsuario);
    switch (intent) {
      case ChocoIntent.fueraDeContexto:
        return const ChocoResponse(texto: _fueraContexto);
      case ChocoIntent.crearViaje:
        return ChocoResponse(
          texto: _elegir(const [
                'Te llevo al flujo «Nueva aventura» para armar el viaje con tu grupo.',
                'Perfecto: empecemos tu viaje nuevo con buena energía.',
              ]) ??
              'Te llevo al flujo «Nueva aventura».',
          acciones: [
            ChocoAction(
              id: 'crear_viaje',
              etiqueta: 'Nueva aventura',
              ejecutar: navegarNuevaAventura,
            ),
          ],
        );
      case ChocoIntent.mesaChoco:
        return ChocoResponse(
          texto: 'La Mesa de Choco es donde el grupo alinea favoritos, presupuesto y tiempos. Cuando todos votan, se abre con más sentido.',
          acciones: [
            if (navegarMesaChoco != null)
              ChocoAction(id: 'mesa', etiqueta: 'Ver Mesa de Choco', ejecutar: navegarMesaChoco),
          ],
        );
      case ChocoIntent.priorizarCategorias:
        return ChocoResponse(
          texto: 'Puedes ordenar hasta 5 categorías para que Choco desempate con tu estilo (gastronomía, noche, relax…).',
          acciones: [
            if (navegarPriorizar != null)
              ChocoAction(id: 'priorizar', etiqueta: 'Prioriza tu aventura', ejecutar: navegarPriorizar),
          ],
        );
      case ChocoIntent.codigoInvitacion:
        final v = _viajePorMencion(textoUsuario) ?? _viajePorDefecto();
        return ChocoResponse(
          texto: 'El código de «${v.nombreViaje}» es ${v.codigoInvitacion}. El enlace corto es ${v.linkInvitacion}.',
          acciones: [
            ChocoAction(
              id: 'copiar_codigo',
              etiqueta: 'Copiar código',
              ejecutar: (c) async {
                await Clipboard.setData(ClipboardData(text: v.codigoInvitacion));
                if (c.mounted) {
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                }
              },
            ),
          ],
        );
      case ChocoIntent.estadoGrupoVoto:
        return ChocoResponse(
          texto: 'Perfecto. En la vista de grupo ves cuántas personas ya votaron y cuándo se habilita la mesa.',
          acciones: [
            if (abrirEstadoGrupo != null)
              ChocoAction(id: 'estado', etiqueta: 'Ver estado del grupo', ejecutar: abrirEstadoGrupo),
          ],
        );
      case ChocoIntent.explorarActividades:
        final destino = _extraerDestino(textoUsuario) ?? 'cartagena';
        final rico = _viajePorMencion(textoUsuario);
        final destinoNombre = _nombreDestino(destino);
        return ChocoResponse(
          texto: _elegir([
                'Te puedo mostrar actividades para $destinoNombre: cultura, gastronomía y planes de noche.',
                'Genial: armamos ideas chéveres para $destinoNombre.',
                'Vamos con actividades en $destinoNombre.',
              ]) ??
              'Te puedo mostrar actividades para $destinoNombre.',
          acciones: [
            ChocoAction(
              id: 'explorar',
              etiqueta: 'Explorar $destinoNombre',
              ejecutar: (c) => abrirExplorar(c, destino),
            ),
            if (rico != null)
              ChocoAction(
                id: 'explorar_viaje',
                etiqueta: 'Ir al viaje «${rico.nombreViaje}»',
                ejecutar: (c) => navegarExplorarActividades(
                  c,
                  destinoKey: rico.destinoKey,
                  viajeId: '${rico.id}',
                  nombreViaje: rico.nombreViaje,
                ),
              ),
          ],
        );
      case ChocoIntent.itinerario:
        return ChocoResponse(
          texto: _elegir(const [
                'Tu itinerario está en la pestaña inferior «Itinerario».',
                'Si el plan ya está listo, lo ves día por día en Itinerario.',
              ]) ??
              'Abre la pestaña «Itinerario» abajo.',
          acciones: [
            ChocoAction(id: 'itinerario', etiqueta: 'Ir a itinerario', ejecutar: (_) => verItinerario()),
          ],
        );
      case ChocoIntent.balancesDebo:
        return ChocoResponse(
          texto: _elegir(const [
                'Te muestro tus balances pendientes en Gastos.',
                'Vamos a revisar cuánto sumas por pagar.',
              ]) ??
              'Te muestro tus balances pendientes.',
          acciones: [
            ChocoAction(id: 'gastos', etiqueta: 'Ver gastos', ejecutar: (_) => verGastos()),
          ],
        );
      case ChocoIntent.balancesMeDeben:
        return ChocoResponse(
          texto: _elegir(const [
                'En Gastos ves quién te debe por viaje.',
                'Revisemos juntos lo que te deben en la pestaña Gastos.',
              ]) ??
              'En Gastos ves quién te debe por viaje.',
          acciones: [
            ChocoAction(id: 'gastos', etiqueta: 'Ver gastos', ejecutar: (_) => verGastos()),
          ],
        );
      case ChocoIntent.unirseViaje:
        return ChocoResponse(
          texto: 'Para unirte pide el código o el enlace de invitación al creador del viaje. Cuando lo tengas, lo pegas en «Unirse» (pronto aquí mismo).',
        );
      case ChocoIntent.registrarGasto:
        final monto = _extraerMonto(textoUsuario);
        final base = monto != null
            ? 'Entendí un posible gasto por ${formatoCop(monto)} COP. ¿Fue compartido o solo tuyo?'
            : 'Parece un gasto. ¿Lo revisamos antes de guardarlo?';
        return ChocoResponse(
          texto: base,
          sugerirRevisionGasto: true,
        );
      case ChocoIntent.ayudaGeneral:
        if (textoUsuario.toLowerCase().contains('bogot') && textoUsuario.toLowerCase().contains('hacer')) {
          return ChocoResponse(
            texto: 'En Bogotá hay planes de cultura, gastronomía y noche. Te llevo a explorar actividades.',
            acciones: [
              ChocoAction(id: 'bog', etiqueta: 'Explorar Bogotá', ejecutar: (c) => abrirExplorar(c, 'bogota')),
            ],
          );
        }
        return ChocoResponse(
          texto: _elegir(const [
                'Cuéntame si vas por gastos, un viaje nuevo o actividades.',
                '¿Exploramos actividades, revisamos gastos o miramos el itinerario?',
              ]) ??
              'Cuéntame si vas por gastos, un viaje nuevo o actividades.',
        );
    }
  }

  String _nombreDestino(String key) {
    switch (key) {
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
        return 'tu destino';
    }
  }

  String? _extraerDestino(String t) {
    final x = t.toLowerCase();
    if (x.contains('cartagena') || x.contains('costeñ')) return 'cartagena';
    if (x.contains('medell') || x.contains('paisa')) return 'medellin';
    if (x.contains('bogot')) return 'bogota';
    if (x.contains('amazon')) return 'amazonas';
    if (x.contains('cali') || x.contains('salsa')) return 'cali';
    return null;
  }

  double? _extraerMonto(String t) {
    final re = RegExp(r'(\d[\d\.\s]*)\s*mil', caseSensitive: false);
    final m = re.firstMatch(t.toLowerCase());
    if (m != null) {
      final n = double.tryParse(m.group(1)!.replaceAll(RegExp(r'[\.\s]'), ''));
      if (n != null) return n * 1000;
    }
    final re2 = RegExp(r'(\d{4,})');
    final m2 = re2.firstMatch(t);
    if (m2 != null) return double.tryParse(m2.group(1)!);
    return null;
  }
}

/// Navegación reutilizable hacia exploración.
void navegarExplorarActividades(
  BuildContext context, {
  required String destinoKey,
  String? viajeId,
  String? nombreViaje,
  List<String>? preferenciasTags,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ExplorarActividadesSwipeScreen(
        destinoKey: destinoKey,
        viajeId: viajeId,
        nombreViaje: nombreViaje,
        preferenciasTags: preferenciasTags,
      ),
    ),
  );
}
