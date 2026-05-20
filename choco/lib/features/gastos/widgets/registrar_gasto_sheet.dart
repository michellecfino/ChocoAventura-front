import 'dart:convert';

import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/gastos_models.dart';
import '../services/gastos_service.dart';
import 'choco_illustration.dart';

Future<void> mostrarRegistrarGastoSheet(
  BuildContext context, {
  ViajeFinancieroResumen? viajePrefijado,
  required GastosService service,
  required VoidCallback alGuardar,
  int initialTab = 0,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.88,
          child: _RegistrarGastoForm(
            viajePrefijado: viajePrefijado,
            service: service,
            alGuardar: alGuardar,
            initialTab: initialTab,
          ),
        ),
      );
    },
  );
}

class _RegistrarGastoForm extends StatefulWidget {
  final ViajeFinancieroResumen? viajePrefijado;
  final GastosService service;
  final VoidCallback alGuardar;
  final int initialTab;

  const _RegistrarGastoForm({
    required this.viajePrefijado,
    required this.service,
    required this.alGuardar,
    this.initialTab = 0,
  });

  @override
  State<_RegistrarGastoForm> createState() => _RegistrarGastoFormState();
}

class _RegistrarGastoFormState extends State<_RegistrarGastoForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _monto = TextEditingController();
  final _otroDetalle = TextEditingController();
  final _montosLista = TextEditingController();
  final _porcentajesLista = TextEditingController();

  late TabController _tabs;

  final stt.SpeechToText _speechVoz = stt.SpeechToText();
  bool _speechVozOk = false;
  bool _escuchandoVoz = false;
  final TextEditingController _textoVoz = TextEditingController();

  TipoGastoForm _tipo = TipoGastoForm.individual;
  CategoriaGasto _cat = CategoriaGasto.comida;
  TipoDivisionGasto _divisionTipo = TipoDivisionGasto.igual;
  String _pagadorId = 'yo';
  bool _participanTodos = true;
  String _moneda = 'COP';

  ViajeFinancieroResumen? _viajeSel;
  List<ViajeFinancieroResumen> _viajesDisponibles = <ViajeFinancieroResumen>[];
  bool _cargandoViajes = false;

  @override
  void initState() {
    super.initState();
    _viajeSel = widget.viajePrefijado;
    if (widget.viajePrefijado != null) {
      _viajesDisponibles = [widget.viajePrefijado!];
    } else {
      _cargarViajesUsuario();
    }
    final idx = widget.initialTab.clamp(0, 1);
    _tabs = TabController(length: 2, vsync: this, initialIndex: idx);
    _initSpeechVoz();
  }

  Future<void> _cargarViajesUsuario() async {
    final usuarioId = UserSession().user?.id;
    if (usuarioId == null) return;
    setState(() => _cargandoViajes = true);
    try {
      final viajes = await widget.service.fetchViajesPorUsuario(usuarioId);
      if (!mounted) return;
      setState(() {
        _viajesDisponibles = viajes;
        _viajeSel ??= viajes.isNotEmpty ? viajes.first : null;
      });
    } finally {
      if (mounted) setState(() => _cargandoViajes = false);
    }
  }

  Future<void> _initSpeechVoz() async {
    try {
      final ok = await _speechVoz.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            setState(() => _escuchandoVoz = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _escuchandoVoz = false);
        },
      );
      if (mounted) setState(() => _speechVozOk = ok);
    } catch (_) {
      if (mounted) setState(() => _speechVozOk = false);
    }
  }

  Future<void> _alternarVozGasto() async {
    if (!_speechVozOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No pude activar el micrófono. Escribe lo que gastaste.', style: AppFonts.body(14))),
        );
      }
      return;
    }
    if (_escuchandoVoz) {
      await _speechVoz.stop();
      if (mounted) setState(() => _escuchandoVoz = false);
      return;
    }
    setState(() => _escuchandoVoz = true);
    try {
      await _speechVoz.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() {
            _textoVoz.text = r.recognizedWords;
            _textoVoz.selection = TextSelection.fromPosition(TextPosition(offset: _textoVoz.text.length));
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
      if (mounted) setState(() => _escuchandoVoz = false);
    }
  }

  Future<void> _procesarVozConChoco() async {
    if (_viajeSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige primero el viaje arriba o en la pestaña Manual.')),
      );
      return;
    }
    final t = _textoVoz.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cuéntale a Choco qué gastaste o pulsa el micrófono.', style: AppFonts.body(14))),
      );
      return;
    }
    final interp = widget.service.interpretarTextoLibre(t);
    await mostrarInterpretacionChoco(
      context,
      data: interp,
      service: widget.service,
      viaje: _viajeSel!,
      alGuardar: widget.alGuardar,
      cerrarPadre: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    try {
      _speechVoz.stop();
    } catch (_) {}
    _textoVoz.dispose();
    _tabs.dispose();
    _desc.dispose();
    _monto.dispose();
    _otroDetalle.dispose();
    _montosLista.dispose();
    _porcentajesLista.dispose();
    super.dispose();
  }

  String? _divisionApi() {
    switch (_divisionTipo) {
      case TipoDivisionGasto.igual:
        return 'IGUAL';
      case TipoDivisionGasto.montosExactos:
        return 'MONTOS';
      case TipoDivisionGasto.porcentajes:
        return 'PORCENTAJES';
    }
  }

  String? _construirDetalleDivisionJson(double montoTotal) {
    if (_tipo != TipoGastoForm.compartido) return null;
    if (_divisionTipo == TipoDivisionGasto.igual) return null;

    if (_divisionTipo == TipoDivisionGasto.montosExactos) {
      final partes = _montosLista.text
          .split(RegExp(r'[\s,;]+'))
          .where((e) => e.isNotEmpty)
          .map((e) => double.tryParse(e.replaceAll('.', '')))
          .whereType<double>()
          .toList();
      if (partes.isEmpty) return null;
      final map = <String, double>{};
      for (var i = 0; i < partes.length; i++) {
        map['${i + 1}'] = partes[i];
      }
      return jsonEncode({'tipo': 'MONTOS', 'montosPorPerfil': map});
    }

    if (_divisionTipo == TipoDivisionGasto.porcentajes) {
      final partes = _porcentajesLista.text
          .split(RegExp(r'[\s,;]+'))
          .where((e) => e.isNotEmpty)
          .map((e) => double.tryParse(e.replaceAll(',', '.')))
          .whereType<double>()
          .toList();
      if (partes.isEmpty) return null;
      final sum = partes.fold<double>(0, (a, b) => a + b);
      if ((sum - 100).abs() > 2) {
        return jsonEncode({'tipo': 'PORCENTAJES', 'invalido': true, 'suma': sum});
      }
      final map = <String, double>{};
      for (var i = 0; i < partes.length; i++) {
        map['${i + 1}'] = partes[i];
      }
      return jsonEncode({'tipo': 'PORCENTAJES', 'porcentajesPorPerfil': map});
    }
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_viajeSel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige un viaje.')),
      );
      return;
    }

    final monto = double.tryParse(_monto.text.replaceAll('.', '').replaceAll(',', ''));
    if (monto == null || monto <= 0) return;

    final v = _viajeSel!;
    final tipoApi = _tipo == TipoGastoForm.individual ? 'INDIVIDUAL' : 'COMPARTIDO';
    final catFinal =
        _cat == CategoriaGasto.otro ? _otroDetalle.text.trim() : _cat.etiqueta;

    final descBase = _desc.text.trim();
    final descripcionFinal =
        _moneda == 'COP' ? descBase : '$descBase ($_moneda)';

    final detalleJson = _construirDetalleDivisionJson(monto);
    if (_tipo == TipoGastoForm.compartido && _divisionTipo == TipoDivisionGasto.montosExactos) {
      if (detalleJson == null || detalleJson.contains('montosPorPerfil":{}')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indica montos separados por coma.')),
        );
        return;
      }
    }
    if (_tipo == TipoGastoForm.compartido && _divisionTipo == TipoDivisionGasto.porcentajes) {
      if (detalleJson != null && detalleJson.contains('"invalido":true')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los porcentajes deben sumar 100 (±2).')),
        );
        return;
      }
    }

    final navigator = Navigator.of(context);

    await widget.service.registrarGasto(
      idGrupo: v.idViaje,
      perfilId: v.perfilId,
      descripcion: descripcionFinal,
      monto: monto,
      tipoApi: tipoApi,
      categoria: catFinal,
      pagadoPorPerfilId: v.perfilId,
      participantesIds: _tipo == TipoGastoForm.compartido && _participanTodos ? null : [v.perfilId],
      division: _divisionApi(),
      detalleDivisionJson: detalleJson,
    );

    if (!context.mounted) return;
    navigator.pop();
    widget.alGuardar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(child: Text('Registrar gasto', style: AppFonts.title(19))),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: AppColors.text.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          labelStyle: AppFonts.label(13, weight: FontWeight.w800),
          unselectedLabelStyle: AppFonts.label(13, weight: FontWeight.w600),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text.withValues(alpha: 0.55),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Manual'),
            Tab(text: 'Voz con Choco'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _panelManual(),
              _panelVozConChoco(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panelManual() {
    final viajes = _viajesDisponibles;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.viajePrefijado == null) ...[
              Text('¿A qué viaje va?', style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.78))),
              const SizedBox(height: 8),
              if (_cargandoViajes)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (viajes.isEmpty)
                Text('No tienes viajes reales disponibles para registrar gastos.', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65)))
              else
                DropdownButtonFormField<ViajeFinancieroResumen>(
                  key: ValueKey(_viajeSel?.idViaje ?? 'viaje'),
                  decoration: _decoration('Viaje'),
                  items: viajes
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.nombreViaje, style: AppFonts.body(14))))
                      .toList(),
                  initialValue: viajes.any((v) => v.idViaje == _viajeSel?.idViaje) ? _viajeSel : null,
                  onChanged: (v) => setState(() => _viajeSel = v),
                  validator: (v) => v == null ? 'Elige un viaje' : null,
                ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _desc,
              style: AppFonts.body(14),
              decoration: _decoration('¿Qué fue?'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Describe el gasto' : null,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _monto,
                    style: AppFonts.body(14),
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Monto'),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', ''));
                      if (n == null || n <= 0) return 'Indica un monto válido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_moneda),
                    decoration: _decoration('Moneda'),
                    initialValue: _moneda,
                    items: const [
                      DropdownMenuItem(value: 'COP', child: Text('COP')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'MXN', child: Text('MXN')),
                    ],
                    onChanged: (v) => setState(() => _moneda = v ?? 'COP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Tipo', style: AppFonts.label(12.5, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            SegmentedButton<TipoGastoForm>(
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              segments: [
                ButtonSegment(
                  value: TipoGastoForm.individual,
                  label: Text('Solo mío', style: AppFonts.label(12)),
                ),
                ButtonSegment(
                  value: TipoGastoForm.compartido,
                  label: Text('Compartido', style: AppFonts.label(12)),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            if (_tipo == TipoGastoForm.compartido) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_pagadorId),
                decoration: _decoration('¿Quién pagó?'),
                initialValue: _pagadorId,
                items: const [DropdownMenuItem(value: 'yo', child: Text('Yo'))],
                onChanged: (v) => setState(() => _pagadorId = v ?? 'yo'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Participaron todos', style: AppFonts.body(14)),
                value: _participanTodos,
                activeThumbColor: AppColors.primary,
                onChanged: (b) => setState(() => _participanTodos = b),
              ),
              Text('División', style: AppFonts.label(12.5, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              ...TipoDivisionGasto.values.map(
                (d) => RadioListTile<TipoDivisionGasto>(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  value: d,
                  groupValue: _divisionTipo,
                  activeColor: AppColors.primary,
                  title: Text(d.etiqueta, style: AppFonts.body(13.5)),
                  onChanged: (v) => setState(() => _divisionTipo = v ?? TipoDivisionGasto.igual),
                ),
              ),
              if (_divisionTipo == TipoDivisionGasto.montosExactos)
                TextFormField(
                  controller: _montosLista,
                  style: AppFonts.body(13.5),
                  decoration: _decoration(
                    'Montos por persona (coma)',
                    hint: 'Ej: 20000, 20000, 20000',
                  ),
                ),
              if (_divisionTipo == TipoDivisionGasto.porcentajes)
                TextFormField(
                  controller: _porcentajesLista,
                  style: AppFonts.body(13.5),
                  decoration: _decoration(
                    'Porcentajes (suman 100)',
                    hint: 'Ej: 40, 35, 25',
                  ),
                ),
            ],
            const SizedBox(height: 10),
            DropdownButtonFormField<CategoriaGasto>(
              key: ValueKey(_cat),
              decoration: _decoration('Categoría'),
              initialValue: _cat,
              items: CategoriaGasto.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.etiqueta, style: AppFonts.body(14))))
                  .toList(),
              onChanged: (v) => setState(() => _cat = v ?? CategoriaGasto.otro),
            ),
            if (_cat == CategoriaGasto.otro) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _otroDetalle,
                style: AppFonts.body(14),
                decoration: _decoration('¿Cuál categoría?'),
                validator: (v) =>
                    _cat == CategoriaGasto.otro && (v == null || v.trim().isEmpty)
                        ? 'Obligatorio si eliges Otro'
                        : null,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar', style: AppFonts.label(14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _guardar,
                    child: Text('Guardar', style: AppFonts.label(14, weight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelVozConChoco() {
    final viajes = _viajesDisponibles;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.viajePrefijado == null) ...[
            Text('¿A qué viaje va?', style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.78))),
            const SizedBox(height: 8),
            if (_cargandoViajes)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (viajes.isEmpty)
              Text('No tienes viajes reales disponibles para registrar gastos.', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65)))
            else
              DropdownButtonFormField<ViajeFinancieroResumen>(
                key: ValueKey('voz_${_viajeSel?.idViaje ?? 'viaje'}'),
                decoration: _decoration('Viaje'),
                items: viajes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.nombreViaje, style: AppFonts.body(14))))
                    .toList(),
                initialValue: viajes.any((v) => v.idViaje == _viajeSel?.idViaje) ? _viajeSel : null,
                onChanged: (v) => setState(() => _viajeSel = v),
              ),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: ChocoIllustration(
                  size: 64,
                  borderRadius: 32,
                  variantSeed: 7,
                  fit: BoxFit.cover,
                  preferPrimaryOnly: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cuéntale a Choco', style: AppFonts.title(16)),
                    const SizedBox(height: 4),
                    Text(
                      'Ej: «Taxi 40 mil para todos, pagué yo». Choco interpreta y confirma antes de guardar.',
                      style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.76), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_escuchandoVoz)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Te escucho…',
                textAlign: TextAlign.center,
                style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.72)),
              ),
            ),
          TextField(
            controller: _textoVoz,
            minLines: 2,
            maxLines: 4,
            style: AppFonts.body(14),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _procesarVozConChoco(),
            decoration: InputDecoration(
              hintText: 'Escribe o dicta tu gasto…',
              fillColor: AppColors.creamLight,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _escuchandoVoz ? 'Detener' : 'Hablar',
                    onPressed: _alternarVozGasto,
                    icon: Icon(
                      _escuchandoVoz ? Icons.stop_rounded : Icons.mic_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Enviar a Choco',
                    onPressed: _procesarVozConChoco,
                    icon: Icon(Icons.send_rounded, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _procesarVozConChoco,
            child: Text('Interpretar con Choco', style: AppFonts.label(14, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _tabs.animateTo(0),
            child: Text('Prefiero el formulario manual', style: AppFonts.label(13.5)),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppFonts.label(12.5, weight: FontWeight.w600),
      hintStyle: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.35)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.creamLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

Future<void> mostrarInterpretacionChoco(
  BuildContext context, {
  required InterpretacionChoco data,
  required GastosService service,
  required ViajeFinancieroResumen viaje,
  required VoidCallback alGuardar,
  VoidCallback? cerrarPadre,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choco entendió esto',
                style: AppFonts.title(20),
              ),
              const SizedBox(height: 12),
              if (data.preguntasPendientes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Antes de guardar, confirma:',
                        style: AppFonts.label(13, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      ...data.preguntasPendientes.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $p', style: AppFonts.body(13, height: 1.35)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              _linea('Gasto', data.descripcion),
              _linea('Monto', formatoCop(data.monto)),
              _linea('Tipo', data.tipo == TipoGastoForm.individual ? 'Solo mío' : 'Compartido'),
              _linea('Pagó', data.pagadorEtiqueta),
              _linea('Participantes', data.participantesEtiqueta),
              _linea('Categoría', data.categoria.etiqueta),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        await service.registrarGasto(
                          idGrupo: viaje.idViaje,
                          perfilId: viaje.perfilId,
                          descripcion: data.descripcion,
                          monto: data.monto,
                          tipoApi: data.tipo == TipoGastoForm.individual ? 'INDIVIDUAL' : 'COMPARTIDO',
                          categoria: data.categoria.etiqueta,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        cerrarPadre?.call();
                        alGuardar();
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _linea(String k, String v) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(k, style: AppFonts.label(13.5, weight: FontWeight.w700))),
        Expanded(child: Text(v, style: AppFonts.body(13.5))),
      ],
    ),
  );
}
