import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/asistente/services/choco_assistant_service.dart';
import 'package:choco/features/flujo_exploracion/screens/espera_grupo_exploracion_screen.dart';
import 'package:choco/features/viajes/screens/crear_viaje_flujo_screen.dart';
import 'package:choco/features/viajes/screens/mesa_choco_screen.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/gastos_models.dart';
import '../services/gastos_service.dart';
import 'choco_illustration.dart';
import 'registrar_gasto_sheet.dart';

/// Asistente global (navbar central).
Future<void> mostrarAsistenteGlobalChoco(
  BuildContext context, {
  required GastosService service,
  required VoidCallback onActualizado,
  ViajeFinancieroResumen? viajeContexto,
}) =>
    abrirPanelChoco(context, service: service, onActualizado: onActualizado, viajeContexto: viajeContexto);

Future<void> abrirPanelChoco(
  BuildContext hostContext, {
  required GastosService service,
  required VoidCallback onActualizado,
  ViajeFinancieroResumen? viajeContexto,
}) {
  return showModalBottomSheet<void>(
    context: hostContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollCtrl) => _ChocoAssistantBody(
        hostContext: hostContext,
        service: service,
        viajeContexto: viajeContexto,
        onActualizado: onActualizado,
        scrollController: scrollCtrl,
      ),
    ),
  );
}

class _MensajeChat {
  final bool esChoco;
  final String texto;
  final List<ChocoAction> acciones;

  const _MensajeChat({
    required this.esChoco,
    required this.texto,
    this.acciones = const [],
  });
}

class _ChocoAssistantBody extends StatefulWidget {
  final BuildContext hostContext;
  final GastosService service;
  final ViajeFinancieroResumen? viajeContexto;
  final VoidCallback onActualizado;
  final ScrollController scrollController;

  const _ChocoAssistantBody({
    required this.hostContext,
    required this.service,
    required this.viajeContexto,
    required this.onActualizado,
    required this.scrollController,
  });

  @override
  State<_ChocoAssistantBody> createState() => _ChocoAssistantBodyState();
}

class _ChocoAssistantBodyState extends State<_ChocoAssistantBody> with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _texto = TextEditingController();
  final ChocoAssistantService _motor = ChocoAssistantService();
  final List<_MensajeChat> _mensajes = [
    const _MensajeChat(
      esChoco: true,
      texto: 'Hola, ¿en qué te ayudo hoy? Puedes elegir una opción o escribirme con calma.',
    ),
  ];

  bool _speechDisponible = false;
  bool _escuchando = false;
  String _mensajeError = '';
  bool _sugerirRevisionGasto = false;

  late AnimationController _pulso;
  late AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _ambient = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final ok = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            _setAnimacionEscucha(false);
            setState(() => _escuchando = false);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _mensajeError = e.errorMsg;
              _escuchando = false;
            });
            _setAnimacionEscucha(false);
          }
        },
      );
      if (mounted) setState(() => _speechDisponible = ok);
    } catch (_) {
      if (mounted) setState(() => _speechDisponible = false);
    }
  }

  void _setAnimacionEscucha(bool activa) {
    if (activa) {
      _ambient.repeat(reverse: true);
      _pulso.repeat(reverse: true);
    } else {
      _ambient.stop();
      _ambient.reset();
      _pulso.stop();
      _pulso.reset();
    }
  }

  @override
  void dispose() {
    try {
      _speech.stop();
    } catch (_) {}
    _pulso.dispose();
    _ambient.dispose();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _alternarVoz() async {
    if (!_speechDisponible) {
      setState(() => _mensajeError = 'No pude activar el micrófono. Puedes escribirme aquí.');
      return;
    }
    if (_escuchando) {
      await _speech.stop();
      setState(() => _escuchando = false);
      _setAnimacionEscucha(false);
      return;
    }
    setState(() {
      _mensajeError = '';
      _escuchando = true;
    });
    _setAnimacionEscucha(true);

    try {
      await _speech.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            _texto.text = r.recognizedWords;
            _texto.selection = TextSelection.fromPosition(TextPosition(offset: _texto.text.length));
          });
        },
        localeId: 'es_CO',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _setAnimacionEscucha(false);
      setState(() {
        _escuchando = false;
        _mensajeError = 'No pude activar el micrófono. Puedes escribirme aquí.';
      });
    }
  }

  void _enviarConversacion() {
    final t = _texto.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escribe algo primero.', style: AppFonts.body(14))),
      );
      return;
    }
    final resp = _motor.responder(
      textoUsuario: t,
      navegarNuevaAventura: (c) {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.hostContext.mounted) return;
          Navigator.of(widget.hostContext).push(
            MaterialPageRoute<void>(builder: (_) => const CrearViajeFlujoScreen()),
          );
        });
      },
      abrirExplorar: (c, destinoKey) {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.hostContext.mounted) return;
          navegarExplorarActividades(
            widget.hostContext,
            destinoKey: destinoKey,
            viajeId: widget.viajeContexto?.idViaje,
            nombreViaje: widget.viajeContexto?.nombreViaje,
          );
        });
      },
      verGastos: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text('Abre la pestaña «Gastos» abajo para ver balances.', style: AppFonts.body(14))),
        );
      },
      verItinerario: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.hostContext).showSnackBar(
          SnackBar(content: Text('Abre la pestaña «Itinerario» abajo.', style: AppFonts.body(14))),
        );
      },
      navegarMesaChoco: (c) {
        Navigator.pop(context);
        final vk = widget.viajeContexto;
        final dk = vk?.destinoKey ?? 'cartagena';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.hostContext.mounted) return;
          Navigator.of(widget.hostContext).push(
            MaterialPageRoute<void>(
              builder: (_) => MesaChocoScreen(
                viajeId: vk?.idViaje,
                nombreViaje: vk?.nombreViaje,
                destinoKey: dk,
              ),
            ),
          );
        });
      },
      navegarPriorizar: (c) {
        Navigator.pop(context);
        final vk = widget.viajeContexto;
        final dk = vk?.destinoKey ?? 'cartagena';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.hostContext.mounted) return;
          Navigator.of(widget.hostContext).push(
            MaterialPageRoute<void>(
              builder: (_) => MesaChocoScreen(
                viajeId: vk?.idViaje,
                destinoKey: dk,
                nombreViaje: vk?.nombreViaje,
              ),
            ),
          );
        });
      },
      abrirEstadoGrupo: (c) {
        Navigator.pop(context);
        final vk = widget.viajeContexto;
        final dk = vk?.destinoKey ?? 'cartagena';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.hostContext.mounted) return;
          Navigator.of(widget.hostContext).push(
            MaterialPageRoute<void>(
              builder: (_) => EsperaGrupoExploracionScreen(
                destinoKey: dk,
                viajeId: vk?.idViaje,
                nombreViaje: vk?.nombreViaje,
                planesInteresantes: 7,
              ),
            ),
          );
        });
      },
    );
    setState(() {
      _mensajes.add(_MensajeChat(esChoco: false, texto: t));
      _texto.clear();
      _mensajes.add(_MensajeChat(esChoco: true, texto: resp.texto, acciones: resp.acciones));
      _sugerirRevisionGasto = resp.sugerirRevisionGasto;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.jumpTo(widget.scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _revisionGasto() async {
    ViajeFinancieroResumen? viaje = widget.viajeContexto;
    if (viaje == null) {
      final usuarioId = UserSession().user?.id;
      if (usuarioId != null) {
        final viajes = await widget.service.fetchViajesPorUsuario(usuarioId);
        viaje = viajes.isNotEmpty ? viajes.first : null;
      }
    }
    if (viaje == null) {
      ScaffoldMessenger.of(widget.hostContext).showSnackBar(
        const SnackBar(content: Text('Primero necesitas al menos un viaje real en la lista.')),
      );
      return;
    }
    var texto = '';
    for (var i = _mensajes.length - 1; i >= 0; i--) {
      if (!_mensajes[i].esChoco) {
        texto = _mensajes[i].texto;
        break;
      }
    }
    final interp = widget.service.interpretarTextoLibre(texto);
    final ViajeFinancieroResumen viajeSeguro = viaje;
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.hostContext.mounted) return;
      mostrarInterpretacionChoco(
        widget.hostContext,
        data: interp,
        service: widget.service,
        viaje: viajeSeguro,
        alGuardar: widget.onActualizado,
      );
    });
  }

  Widget _anillosAlrededor() {
    if (!_escuchando) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryDark.withValues(alpha: 0.48),
                width: 2.5,
              ),
            ),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
          ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, child) {
        final v = _ambient.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 124 + v * 22,
              height: 124 + v * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryDark.withValues(alpha: 0.35 + v * 0.18),
                  width: 2.5,
                ),
              ),
            ),
            Container(
              width: 100 + v * 10,
              height: 100 + v * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.06 + v * 0.05),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(28));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.creamLight,
            AppColors.background,
          ],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWarm,
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Habla con Choco', style: AppFonts.display(20))),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.text.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _anillosAlrededor(),
                        ClipOval(
                          child: ChocoIllustration(
                            size: 84,
                            borderRadius: 42,
                            fit: BoxFit.cover,
                            preferPrimaryOnly: true,
                            overrideAsset: _escuchando ? 'assets/choco/hablando.png' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _escuchando
                      ? ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.06).animate(
                            CurvedAnimation(parent: _pulso, curve: Curves.easeInOut),
                          ),
                          child: _botonMic(),
                        )
                      : _botonMic(),
                  if (_escuchando)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Te escucho…',
                        textAlign: TextAlign.center,
                        style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.72)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _accionChip(Icons.receipt_long_rounded, 'Registrar gasto', () {
                      Navigator.pop(context);
                      mostrarRegistrarGastoSheet(
                        widget.hostContext,
                        viajePrefijado: widget.viajeContexto,
                        service: widget.service,
                        alGuardar: widget.onActualizado,
                      );
                    }),
                    _accionChip(Icons.add_road_rounded, 'Crear viaje', () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!widget.hostContext.mounted) return;
                        Navigator.of(widget.hostContext).push(
                          MaterialPageRoute<void>(builder: (_) => const CrearViajeFlujoScreen()),
                        );
                      });
                    }),
                    _accionChip(Icons.how_to_reg_rounded, 'Unirme a viaje', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(widget.hostContext).showSnackBar(
                        SnackBar(content: Text('Pronto: código de invitación', style: AppFonts.body(14))),
                      );
                    }),
                    _accionChip(Icons.swipe_rounded, 'Explorar actividades', () {
                      final dk = widget.viajeContexto?.destinoKey ?? 'cartagena';
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!widget.hostContext.mounted) return;
                        navegarExplorarActividades(widget.hostContext, destinoKey: dk, viajeId: widget.viajeContexto?.idViaje);
                      });
                    }),
                    _accionChip(Icons.balance_rounded, '¿Cuánto debo?', () {
                      Navigator.pop(context);
                      _dialogoResumen(widget.hostContext, widget.service, debo: true);
                    }),
                    _accionChip(Icons.groups_2_rounded, '¿Quién me debe?', () {
                      Navigator.pop(context);
                      _dialogoResumen(widget.hostContext, widget.service, debo: false);
                    }),
                    _accionChip(Icons.calendar_month_rounded, 'Itinerario', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(widget.hostContext).showSnackBar(
                        SnackBar(content: Text('Abre la pestaña Itinerario abajo', style: AppFonts.body(14))),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                itemCount: _mensajes.length,
                itemBuilder: (context, i) {
                  final m = _mensajes[i];
                  return _MensajeUI(m: m, hostContext: widget.hostContext);
                },
              ),
            ),
            if (_mensajeError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(_mensajeError, style: AppFonts.body(12.5, color: AppColors.owe)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: TextField(
                controller: _texto,
                minLines: 1,
                maxLines: 3,
                style: AppFonts.body(14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarConversacion(),
                decoration: InputDecoration(
                  hintText: 'Escribe tu mensaje…',
                  fillColor: AppColors.surfaceElevated,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  suffixIcon: IconButton(
                    tooltip: 'Enviar',
                    onPressed: _enviarConversacion,
                    icon: Icon(Icons.send_rounded, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ),
            if (_sugerirRevisionGasto)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _revisionGasto,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text('Revisar como gasto', style: AppFonts.label(13.5, weight: FontWeight.w800)),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _botonMic() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: _alternarVoz,
      icon: Icon(_escuchando ? Icons.stop_rounded : Icons.mic_rounded, size: 22),
      label: Text(
        _escuchando ? 'Detener' : 'Escuchar',
        style: AppFonts.label(13.5, weight: FontWeight.w800).copyWith(color: Colors.white),
      ),
    );
  }

  Widget _accionChip(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: AppColors.primaryDark),
        label: Text(label, style: AppFonts.label(12, weight: FontWeight.w700)),
        backgroundColor: AppColors.surfaceElevated,
        side: BorderSide(color: AppColors.outlineSoft),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: onTap,
      ),
    );
  }

  static void _dialogoResumen(BuildContext context, GastosService service, {required bool debo}) {
    final usuarioId = UserSession().user?.id;
    if (usuarioId == null) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gastos'),
          content: const Text('Inicia sesión para ver tus saldos reales.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(debo ? '¿Cuánto debes?' : '¿Cuánto te deben?'),
        content: FutureBuilder<List<ViajeFinancieroResumen>>(
          future: service.fetchViajesPorUsuario(usuarioId),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(height: 52, child: Center(child: CircularProgressIndicator()));
            }
            final viajes = snap.data ?? const <ViajeFinancieroResumen>[];
            double total = 0;
            for (final v in viajes) {
              total += debo ? v.tuDebes : v.teDeben;
            }
            return Text(
              debo
                  ? 'En tus viajes reales sumas unos ${formatoCop(total)} pendientes por pagar.'
                  : 'En tus viajes reales te deben unos ${formatoCop(total)} en total.',
              style: AppFonts.body(14, height: 1.45),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _MensajeUI extends StatelessWidget {
  final _MensajeChat m;
  final BuildContext hostContext;

  const _MensajeUI({required this.m, required this.hostContext});

  @override
  Widget build(BuildContext context) {
    final bg = m.esChoco ? AppColors.surfaceElevated : AppColors.primary.withValues(alpha: 0.18);
    final fg = m.esChoco ? AppColors.text : AppColors.primaryDark;
    return Align(
      alignment: m.esChoco ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(m.esChoco ? 4 : 18),
            bottomRight: Radius.circular(m.esChoco ? 18 : 4),
          ),
          border: Border.all(color: AppColors.outlineSoft.withValues(alpha: m.esChoco ? 1 : 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.texto,
              style: AppFonts.body(14, color: fg, height: 1.35),
            ),
            if (m.esChoco && m.acciones.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: m.acciones.map((a) {
                  return FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => a.ejecutar?.call(hostContext),
                    child: Text(a.etiqueta, style: AppFonts.label(12.5, weight: FontWeight.w800)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
