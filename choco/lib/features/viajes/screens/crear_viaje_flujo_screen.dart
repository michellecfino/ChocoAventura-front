import 'dart:async';

import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/features/actividades/screens/explorar_actividades_swipe_screen.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Flujo corto: datos del viaje → preferencias → cierre con exploración automática.
class CrearViajeFlujoScreen extends StatefulWidget {
  final GrupoViajeModel? viajeBorrador;

  const CrearViajeFlujoScreen({super.key, this.viajeBorrador});

  @override
  State<CrearViajeFlujoScreen> createState() => _CrearViajeFlujoScreenState();
}

class _CrearViajeFlujoScreenState extends State<CrearViajeFlujoScreen> {
  final _page = PageController();
  int _i = 0;
  Timer? _autoExplorar;

  final _nombre = TextEditingController();
  String _destinoKey = 'cartagena';
  DateTime? _fechaIni;
  DateTime? _fechaFin;
  final _personas = TextEditingController(text: '4');
  final _presupuesto = TextEditingController(text: '800000');
  final Set<String> _prefSel = {};
  String _codigoInvitacion = '';

  static const _destinosUi = <(String key, String label)>[
    ('amazonas', 'Amazonas'),
    ('bogota', 'Bogotá'),
    ('cali', 'Cali'),
    ('cartagena', 'Cartagena'),
    ('medellin', 'Medellín'),
  ];

  @override
  void dispose() {
    _autoExplorar?.cancel();
    _page.dispose();
    _nombre.dispose();
    _personas.dispose();
    _presupuesto.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final b = widget.viajeBorrador;
    if (b != null) {
      _nombre.text = b.nombreViaje;
      _destinoKey = b.destinoKey.toLowerCase();
      _personas.text = '${b.participantes}';
    }
  }

  void _programarExploracionAuto() {
    _autoExplorar?.cancel();
    _autoExplorar = Timer(const Duration(seconds: 2), () {
      if (!mounted || _i != 2) return;
      _irExplorar();
    });
  }

  void _irExplorar() {
    _autoExplorar?.cancel();
    if (!mounted) return;
    final dk = _destinoKey;
    final tags = _prefSel.toList();
    final nombre = _nombre.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ExplorarActividadesSwipeScreen(
          destinoKey: dk,
          nombreViaje: nombre.isEmpty ? null : nombre,
          preferenciasTags: tags.isEmpty ? null : tags,
        ),
      ),
    );
  }

  Future<void> _pickIni() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _fechaIni ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      locale: const Locale('es', 'CO'),
    );
    if (d != null) {
      setState(() {
        _fechaIni = d;
        if (_fechaFin != null && _fechaFin!.isBefore(d)) {
          _fechaFin = d;
        }
      });
    }
  }

  Future<void> _pickFin() async {
    final base = _fechaIni ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? base,
      firstDate: base,
      lastDate: DateTime(base.year + 3),
      locale: const Locale('es', 'CO'),
    );
    if (d != null) setState(() => _fechaFin = d);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Elegir fecha';
    return DateFormat.yMMMMd('es').format(d);
  }

  bool _validarDatos() {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ponle un nombre a tu viaje.', style: AppFonts.body(14))),
      );
      return false;
    }
    if (_fechaIni == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Elige fecha de inicio y fin.', style: AppFonts.body(14))),
      );
      return false;
    }
    if (_fechaFin!.isBefore(_fechaIni!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La fecha de fin no puede ser antes que el inicio.', style: AppFonts.body(14))),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Nueva aventura', style: AppFonts.title(17)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (j) {
                final act = j <= _i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    act ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: act ? AppColors.primaryDark : AppColors.text.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (v) {
                setState(() => _i = v);
                if (v == 2) {
                  _programarExploracionAuto();
                }
              },
              children: [
                _paginaDatos(),
                _paginaPreferencias(),
                _paginaCierre(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginaDatos() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Datos del viaje', style: AppFonts.title(18)),
        const SizedBox(height: 8),
        Text(
          'Cuéntale a Choco por chat o voz más tarde; aquí dejamos lo esencial listo en un momento.',
          style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.78)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nombre,
          style: AppFonts.body(14),
          decoration: _dec('Nombre del viaje'),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: _dec('Destino'),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _destinoKey,
              items: _destinosUi
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2, style: AppFonts.body(14)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _destinoKey = v ?? 'cartagena'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickIni,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _dec('Fecha de inicio'),
                  child: Text(_fmt(_fechaIni), style: AppFonts.body(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickFin,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _dec('Fecha de fin'),
                  child: Text(_fmt(_fechaFin), style: AppFonts.body(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _personas,
          keyboardType: TextInputType.number,
          style: AppFonts.body(14),
          decoration: _dec('Personas estimadas'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _presupuesto,
          keyboardType: TextInputType.number,
          style: AppFonts.body(14),
          decoration: _dec('Presupuesto inicial (COP, opcional)'),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () {
            if (!_validarDatos()) return;
            _codigoInvitacion = 'CHOCO-${DateTime.now().millisecondsSinceEpoch % 100000}';
            _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          },
          child: Text('Continuar', style: AppFonts.label(14, weight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _paginaPreferencias() {
    const tags = [
      'Naturaleza',
      'Cultura',
      'Gastronomía',
      'Aventura',
      'Relax',
      'Noche',
      'Playa',
      'Bajo costo',
      'Vida local',
      'Fotos',
      'Familia',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('Tus preferencias', style: AppFonts.title(18)),
        const SizedBox(height: 8),
        Text(
          'Elige lo que más te motive para este viaje (puedes marcar varias).',
          style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.78)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (t) => FilterChip(
                  label: Text(t),
                  selected: _prefSel.contains(t),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _prefSel.add(t);
                    } else {
                      _prefSel.remove(t);
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _page.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: const Text('Atrás'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: Text('Siguiente', style: AppFonts.label(14, weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paginaCierre() {
    final nombre = _nombre.text.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Text('¡Listo para explorar!', style: AppFonts.title(18)),
        const SizedBox(height: 10),
        Text(
          'Choco preparó actividades para tu viaje. Ahora elige las que más te suenen.',
          style: AppFonts.body(14, height: 1.45),
        ),
        const SizedBox(height: 16),
        if (_codigoInvitacion.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creamLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invita a tu grupo', style: AppFonts.label(12, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                SelectableText(_codigoInvitacion, style: AppFonts.display(18)),
                const SizedBox(height: 4),
                SelectableText(
                  'https://chocoaventura.app/i/$_codigoInvitacion',
                  style: AppFonts.body(12.5, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _irExplorar,
          child: Text('Explorar ahora', style: AppFonts.label(14, weight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _autoExplorar?.cancel();
            _page.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          },
          child: Text('Atrás', style: AppFonts.label(13.5)),
        ),
        const SizedBox(height: 10),
        Text(
          'En unos segundos te llevamos solito a la exploración…',
          textAlign: TextAlign.center,
          style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.65)),
        ),
        if (nombre.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Viaje: $nombre',
            textAlign: TextAlign.center,
            style: AppFonts.label(12, weight: FontWeight.w700),
          ),
        ],
      ],
    );
  }

  InputDecoration _dec(String l) => InputDecoration(
        labelText: l,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.surfaceElevated,
      );
}
