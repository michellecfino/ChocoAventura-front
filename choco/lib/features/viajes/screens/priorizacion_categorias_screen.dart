import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/flujo_exploracion/prioridad_aventura_memoria.dart';
import 'package:choco/features/viajes/services/priorizacion_categorias_service.dart';
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
  static const _fallbackPool = [
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
  final PriorizacionCategoriasService _service = const PriorizacionCategoriasService();

  List<String> _pool = List<String>.from(_fallbackPool);
  bool _cargandoCategorias = false;
  bool _guardando = false;
  int _totalParticipantes = 0;
  int _participantesPriorizados = 0;
  int _faltanPorPriorizar = 0;
  bool _listoParaItinerario = false;

  String get _clave => PrioridadAventuraMemoria.clave(viajeId: widget.viajeId, destinoKey: widget.destinoKey);

  @override
  void initState() {
    super.initState();
    final prev = PrioridadAventuraMemoria.leerOrden(_clave);
    if (prev != null) {
      _orden.addAll(prev.where((e) => _pool.contains(e)));
    }
    _cargarCategoriasDisponibles();
  }

  Future<void> _cargarCategoriasDisponibles() async {
    final grupoId = int.tryParse(widget.viajeId ?? '');
    if (grupoId == null || !_service.backendConfigurado) return;

    setState(() => _cargandoCategorias = true);
    try {
      final estado = await _service.cargarEstado(
        grupoViajeId: grupoId,
        usuarioId: UserSession().user?.id,
      );
      if (!mounted || estado == null) return;
      final categorias = estado.categoriasDisponibles;
      setState(() {
        _totalParticipantes = estado.totalParticipantes;
        _participantesPriorizados = estado.participantesPriorizados;
        _faltanPorPriorizar = estado.faltanPorPriorizar;
        _listoParaItinerario = estado.listoParaItinerario;
        if (categorias.isNotEmpty) {
          _pool = categorias.map((c) => c.nombre).toList();
          _orden.removeWhere((e) => !_pool.contains(e));
        }
      });
    } catch (_) {
      // Mantiene el pool local para que la pantalla siga funcionando sin backend.
    } finally {
      if (mounted) setState(() => _cargandoCategorias = false);
    }
  }

  void _agregar(String o) {
    if (_orden.contains(o) || _orden.length >= 5) return;
    setState(() => _orden.add(o));
  }

  void _quitar(String o) {
    setState(() => _orden.remove(o));
  }

  Future<void> _confirmar() async {
    final messenger = ScaffoldMessenger.of(context);
    final orden = List<String>.from(_orden);
    PrioridadAventuraMemoria.guardar(_clave, orden);

    final grupoId = int.tryParse(widget.viajeId ?? '');
    bool guardadoEnBackend = false;
    if (grupoId != null && _service.backendConfigurado) {
      setState(() => _guardando = true);
      try {
        await _service.guardarRanking(
          grupoViajeId: grupoId,
          usuarioId: UserSession().user?.id,
          categoriasOrdenadas: orden,
        );
        guardadoEnBackend = true;
        final estado = await _service.cargarEstado(
          grupoViajeId: grupoId,
          usuarioId: UserSession().user?.id,
        );
        if (estado != null && mounted) {
          setState(() {
            _totalParticipantes = estado.totalParticipantes;
            _participantesPriorizados = estado.participantesPriorizados;
            _faltanPorPriorizar = estado.faltanPorPriorizar;
            _listoParaItinerario = estado.listoParaItinerario;
          });
        }
      } catch (_) {
        guardadoEnBackend = false;
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          guardadoEnBackend
              ? 'Prioridades guardadas. Choco las usará para generar el itinerario.'
              : 'Prioridades guardadas localmente. Choco las usará cuando el backend esté disponible.',
          style: AppFonts.body(14),
        ),
      ),
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
            if (_totalParticipantes > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _listoParaItinerario
                      ? Colors.green.withValues(alpha: 0.10)
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outlineSoft),
                ),
                child: Text(
                  _listoParaItinerario
                      ? 'Todos priorizaron. El itinerario ya se puede generar.'
                      : 'Han priorizado $_participantesPriorizados de $_totalParticipantes. Faltan $_faltanPorPriorizar para desbloquear el itinerario.',
                  style: AppFonts.body(12.5, height: 1.35),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Añadir categoría', style: AppFonts.label(12.5, weight: FontWeight.w800)),
                if (_cargandoCategorias) ...[
                  const SizedBox(width: 8),
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ],
            ),
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
                      : (_) => ya ? _quitar(o) : _agregar(o),
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
                      buildDefaultDragHandles: false,
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
                                ReorderableDragStartListener(
                                  index: i,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                      child: Icon(Icons.drag_handle_rounded,
                                          color: AppColors.text.withValues(alpha: 0.55)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            FilledButton(
              onPressed: _orden.isEmpty || _guardando ? null : _confirmar,
              child: Text(
                _guardando ? 'Guardando...' : 'Confirmar prioridades',
                style: AppFonts.label(14, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
