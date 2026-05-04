import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/features/flujo_exploracion/prioridad_aventura_memoria.dart';
import 'package:flutter/material.dart';

/// Fase «Prioriza tu aventura»: hasta 5 categorías, orden arrastrable (Top 5).
class PriorizacionCategoriasScreen extends StatefulWidget {
  final String? viajeId;
  final String destinoKey;
  final String? nombreViaje;

  const PriorizacionCategoriasScreen({
    super.key,
    this.viajeId,
    this.destinoKey = 'cartagena',
    this.nombreViaje,
  });

  @override
  State<PriorizacionCategoriasScreen> createState() => _PriorizacionCategoriasScreenState();
}

class _PriorizacionCategoriasScreenState extends State<PriorizacionCategoriasScreen> {
  static const _pool = [
    'Gastronomía',
    'Naturaleza',
    'Cultura',
    'Aventura',
    'Relax',
    'Bajo costo',
    'Noche',
    'Fotos',
    'Playa',
    'Vida local',
  ];

  final List<String> _orden = [];

  String get _clave => PrioridadAventuraMemoria.clave(viajeId: widget.viajeId, destinoKey: widget.destinoKey);

  @override
  void initState() {
    super.initState();
    final prev = PrioridadAventuraMemoria.leerOrden(_clave);
    if (prev != null) {
      _orden.addAll(prev.where((e) => _pool.contains(e)));
    }
  }

  void _agregar(String o) {
    if (_orden.contains(o) || _orden.length >= 5) return;
    setState(() => _orden.add(o));
  }

  void _quitar(String o) {
    setState(() => _orden.remove(o));
  }

  void _confirmar() {
    final messenger = ScaffoldMessenger.of(context);
    PrioridadAventuraMemoria.guardar(_clave, List<String>.from(_orden));
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Prioridades guardadas. Choco las usará en la mesa.', style: AppFonts.body(14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Prioriza tu aventura', style: AppFonts.title(17)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige hasta 5 ingredientes y ordénalos: lo primero pesa más cuando haya empates en la Mesa de Choco.',
              style: AppFonts.body(14, height: 1.45),
            ),
            if (widget.nombreViaje != null && widget.nombreViaje!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.nombreViaje!.trim(),
                style: AppFonts.label(13, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark),
              ),
            ],
            const SizedBox(height: 16),
            Text('Añadir categoría', style: AppFonts.label(12.5, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pool.map((o) {
                final ya = _orden.contains(o);
                final lleno = !ya && _orden.length >= 5;
                return FilterChip(
                  label: Text(o, style: AppFonts.label(13, weight: FontWeight.w600)),
                  selected: ya,
                  onSelected: lleno
                      ? null
                      : (sel) {
                          if (sel) {
                            _agregar(o);
                          } else {
                            _quitar(o);
                          }
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Tu top (arrastra para ordenar)', style: AppFonts.label(12.5, weight: FontWeight.w800)),
                const Spacer(),
                Text('${_orden.length}/5', style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.65))),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _orden.isEmpty
                  ? Center(
                      child: Text(
                        'Toca las categorías de arriba para armar tu ranking.',
                        textAlign: TextAlign.center,
                        style: AppFonts.body(14, color: AppColors.text.withValues(alpha: 0.62)),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _orden.length,
                      onReorder: (oldI, newI) {
                        setState(() {
                          if (newI > oldI) newI -= 1;
                          final x = _orden.removeAt(oldI);
                          _orden.insert(newI, x);
                        });
                      },
                      itemBuilder: (context, i) {
                        final o = _orden[i];
                        return Card(
                          key: ValueKey<String>(o),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.outlineSoft),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: Text('${i + 1}', style: AppFonts.label(14, weight: FontWeight.w900)),
                            ),
                            title: Text(o, style: AppFonts.body(15, weight: FontWeight.w700)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => _quitar(o),
                                ),
                                const Icon(Icons.drag_handle_rounded),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            FilledButton(
              onPressed: _orden.isEmpty ? null : _confirmar,
              child: Text('Confirmar prioridades', style: AppFonts.label(14, weight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
