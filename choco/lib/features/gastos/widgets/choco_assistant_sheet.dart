import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/gastos_models.dart';
import '../services/gastos_service.dart';
import 'choco_illustration.dart';
import 'registrar_gasto_sheet.dart';

/// Asistente global (navbar central). Misma API que [abrirPanelChoco].
Future<void> mostrarAsistenteGlobalChoco(
  BuildContext context, {
  required GastosService service,
  required VoidCallback onActualizado,
  ViajeFinancieroResumen? viajeContexto,
}) =>
    abrirPanelChoco(context, service: service, onActualizado: onActualizado, viajeContexto: viajeContexto);

/// Abre el panel de Choco (asistente con texto y voz).
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

class _ChocoAssistantBodyState extends State<_ChocoAssistantBody>
    with TickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _texto = TextEditingController();

  bool _speechDisponible = false;
  bool _escuchando = false;
  String _estadoVoz = '';
  String _mensajeError = '';

  late AnimationController _pulso;
  late AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
      try {
      final ok = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          setState(() => _estadoVoz = s);
          if (s == 'done' || s == 'notListening') {
            _pulso.stop();
            setState(() => _escuchando = false);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _mensajeError = e.errorMsg;
              _escuchando = false;
            });
            _pulso.stop();
          }
        },
      );
      if (mounted) setState(() => _speechDisponible = ok);
    } catch (_) {
      if (mounted) setState(() => _speechDisponible = false);
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
      setState(() => _mensajeError =
          'Tu navegador no permite voz ahora. Escríbele a Choco.');
      return;
    }
    if (_escuchando) {
      await _speech.stop();
      setState(() {
        _escuchando = false;
      });
      _pulso.stop();
      return;
    }
    setState(() {
      _mensajeError = '';
      _escuchando = true;
      _estadoVoz = 'listening';
    });
    _pulso.repeat(reverse: true);

    try {
      await _speech.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            _texto.text = r.recognizedWords;
            _texto.selection = TextSelection.fromPosition(TextPosition(offset: _texto.text.length));
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _pulso.stop();
      setState(() {
        _escuchando = false;
        _mensajeError =
            'Tu navegador no permite micrófono o hubo un error. Escríbele a Choco o prueba otro navegador.';
      });
    }
  }

  void _interpretar() {
    final viajes = widget.service.viajesMockActuales();
    final viaje = widget.viajeContexto ?? (viajes.isNotEmpty ? viajes.first : null);
    if (viaje == null) {
      ScaffoldMessenger.of(widget.hostContext).showSnackBar(
        const SnackBar(content: Text('Primero necesitas al menos un viaje en la lista.')),
      );
      return;
    }
    final interp = widget.service.interpretarTextoLibre(_texto.text);
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.hostContext.mounted) return;
      mostrarInterpretacionChoco(
        widget.hostContext,
        data: interp,
        service: widget.service,
        viaje: viaje,
        alGuardar: widget.onActualizado,
      );
    });
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
                  Expanded(
                    child: Text('Habla con Choco', style: AppFonts.display(20)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.text.withValues(alpha: 0.65)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 168,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, child) {
                      final v = _ambient.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130 + v * 28,
                            height: 130 + v * 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.12 + v * 0.08),
                                width: 2,
                              ),
                            ),
                          ),
                          Container(
                            width: 100 + v * 12,
                            height: 100 + v * 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.08 + v * 0.04),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  ClipOval(
                    child: ChocoIllustration(size: 86, borderRadius: 43, variantSeed: 1, fit: BoxFit.cover),
                  ),
                  if (_escuchando)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Choco está escuchando…',
                          style: AppFonts.label(12, weight: FontWeight.w800).copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                children: [
                  Text(
                    'Puedes pedirle gastos, balances, itinerario o crear un viaje.',
                    textAlign: TextAlign.center,
                    style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.82)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _accionRapida(
                        icon: Icons.receipt_long_rounded,
                        label: 'Registrar gasto',
                        onTap: () {
                          Navigator.pop(context);
                          mostrarRegistrarGastoSheet(
                            widget.hostContext,
                            viajePrefijado: widget.viajeContexto,
                            service: widget.service,
                            alGuardar: widget.onActualizado,
                          );
                        },
                      ),
                      _accionRapida(
                        icon: Icons.add_road_rounded,
                        label: 'Crear viaje',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(widget.hostContext, '/login');
                        },
                      ),
                      _accionRapida(
                        icon: Icons.how_to_reg_rounded,
                        label: 'Unirme a viaje',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(widget.hostContext).showSnackBar(
                            SnackBar(content: Text('Pronto: código de invitación', style: AppFonts.body(14))),
                          );
                        },
                      ),
                      _accionRapida(
                        icon: Icons.balance_rounded,
                        label: '¿Cuánto debo?',
                        onTap: () {
                          Navigator.pop(context);
                          _dialogoResumen(widget.hostContext, widget.service, debo: true);
                        },
                      ),
                      _accionRapida(
                        icon: Icons.groups_2_rounded,
                        label: '¿Quién me debe?',
                        onTap: () {
                          Navigator.pop(context);
                          _dialogoResumen(widget.hostContext, widget.service, debo: false);
                        },
                      ),
                      _accionRapida(
                        icon: Icons.calendar_month_rounded,
                        label: 'Itinerario',
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(widget.hostContext).showSnackBar(
                            SnackBar(content: Text('Abre la pestaña Itinerario abajo', style: AppFonts.body(14))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Escribe o dicta', style: AppFonts.title(15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _texto,
                    minLines: 2,
                    maxLines: 4,
                    style: AppFonts.body(14),
                    decoration: InputDecoration(
                      hintText: 'Ej: Taxi cuarenta mil para todos, pagué yo',
                      fillColor: AppColors.surfaceElevated,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_mensajeError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_mensajeError, style: AppFonts.body(12.5, color: AppColors.owe)),
                    ),
                  Row(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.05).animate(
                          CurvedAnimation(parent: _ambient, curve: Curves.easeInOut),
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _alternarVoz,
                          icon: Icon(_escuchando ? Icons.stop_rounded : Icons.mic_rounded, size: 20),
                          label: Text(
                            _escuchando ? 'Detener' : 'Hablar',
                            style: AppFonts.label(13, weight: FontWeight.w800).copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_escuchando)
                        Expanded(
                          child: Text(
                            _estadoVoz.isEmpty ? '…' : _estadoVoz,
                            style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.65)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _interpretar,
                    child: Text('Interpretar y confirmar', style: AppFonts.label(14, weight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accionRapida({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(label, style: AppFonts.label(12.5, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  static void _dialogoResumen(BuildContext context, GastosService service, {required bool debo}) {
    final viajes = service.viajesMockActuales();
    double total = 0;
    for (final v in viajes) {
      total += debo ? v.tuDebes : v.teDeben;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(debo ? '¿Cuánto debes?' : '¿Cuánto te deben?'),
        content: Text(
          debo
              ? 'En tus viajes sumas unos ${formatoCop(total)} pendientes por pagar (vista rápida).'
              : 'En tus viajes te deben unos ${formatoCop(total)} en total (vista rápida).',
          style: AppFonts.body(14, height: 1.45),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
