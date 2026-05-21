import 'dart:async';
import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart' show AssetResolver, nombreLegibleDestino;
import 'package:choco/core/services/user_session.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:choco/features/itinerario/services/ItinerarioService.dart';
import 'package:choco/features/viajes/screens/resumen_actividades_screen.dart';
import 'package:choco/features/viajes/services/priorizacion_categorias_service.dart';
import 'package:flutter/material.dart';

class MesaChocoScreen extends StatefulWidget {
  final String? viajeId;
  final String? nombreViaje;
  final String destinoKey;
  final bool forzarConVotosActuales;

  const MesaChocoScreen({
    super.key,
    this.viajeId,
    this.nombreViaje,
    this.destinoKey = 'cartagena',
    this.forzarConVotosActuales = false,
  });

  @override
  State<MesaChocoScreen> createState() => _MesaChocoScreenState();
}

class _MesaChocoScreenState extends State<MesaChocoScreen> {
  final _priorizacionService = const PriorizacionCategoriasService();
  final _itinerarioService = const ItinerarioService();
  String? _bannerPath;
  PriorizacionCategoriasEstado? _estado;
  List<CategoriaPriorizacionModel> _ranking = <CategoriaPriorizacionModel>[];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  Timer? _refreshTimer;

  int? get _grupoId => int.tryParse(widget.viajeId ?? '');
  int? get _usuarioId => UserSession().user?.id;

  List<CategoriaPriorizacionModel> get _disponibles {
    final estado = _estado;
    if (estado == null) return const [];
    final usados = _ranking.map((e) => e.categoriaId).toSet();
    return estado.categoriasDisponibles.where((c) => !usados.contains(c.categoriaId)).toList();
  }

  bool get _usuarioYaPriorizo => _estado?.usuarioActualPriorizo == true;
  bool get _listoGrupo => _estado?.listoParaItinerario == true;
  bool get _puedeEditar => !_usuarioYaPriorizo && !_listoGrupo;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_puedeEditar) _cargarEstado();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    await Future.wait([_cargarBanner(), _cargarEstado()]);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarBanner() async {
    try {
      final resolver = await AssetResolver.instance();
      final path = resolver.resolveDestinoImage(widget.destinoKey);
      if (mounted) setState(() => _bannerPath = path);
    } catch (_) {}
  }

  Future<void> _cargarEstado() async {
    final grupoId = _grupoId;
    if (grupoId == null) {
      if (mounted) setState(() => _error = 'No encontré el viaje actual.');
      return;
    }
    try {
      final estado = await _priorizacionService.cargarEstado(
        grupoViajeId: grupoId,
        usuarioId: _usuarioId,
      );
      if (!mounted) return;
      setState(() {
        _estado = estado;
        _ranking = _rankingDesdeEstado(estado);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No pude cargar la Mesa de Choco desde el backend.');
    }
  }

  List<CategoriaPriorizacionModel> _rankingDesdeEstado(PriorizacionCategoriasEstado? estado) {
    if (estado == null) return <CategoriaPriorizacionModel>[];
    final conPosicion = estado.categoriasDisponibles
        .where((c) => c.posicionActual != null)
        .toList()
      ..sort((a, b) => a.posicionActual!.compareTo(b.posicionActual!));
    return conPosicion;
  }

  void _agregar(CategoriaPriorizacionModel categoria) {
    if (!_puedeEditar) return;
    if (_ranking.any((e) => e.categoriaId == categoria.categoriaId)) return;
    setState(() => _ranking = [..._ranking, categoria]);
  }

  void _quitar(CategoriaPriorizacionModel categoria) {
    if (!_puedeEditar) return;
    setState(() => _ranking = _ranking.where((e) => e.categoriaId != categoria.categoriaId).toList());
  }

  Future<void> _guardarYContinuar() async {
    final grupoId = _grupoId;
    if (grupoId == null) return;
    if (_ranking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elige al menos una categoría.')));
      return;
    }
    setState(() => _guardando = true);
    try {
      await _priorizacionService.guardarRanking(
        grupoViajeId: grupoId,
        usuarioId: _usuarioId,
        categoriasOrdenadas: _ranking.map((c) => c.nombre).toList(),
      );
      final estadoActualizado = await _priorizacionService.cargarEstado(
        grupoViajeId: grupoId,
        usuarioId: _usuarioId,
      );
      if (!mounted) return;
      setState(() {
        _estado = estadoActualizado;
        _ranking = _rankingDesdeEstado(estadoActualizado);
      });

      if (estadoActualizado?.listoParaItinerario == true) {
        final itinerario = await _itinerarioService.crearItinerario(
          nombre: 'Itinerario ${widget.nombreViaje ?? nombreLegibleDestino(widget.destinoKey)}',
          grupoViajeId: grupoId,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResumenActividadesScreen(
              viajeId: widget.viajeId,
              itinerarioId: itinerario.id,
              nombreViaje: widget.nombreViaje,
              destinoKey: widget.destinoKey,
              actividadesElegidas: const [],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tu voto quedó guardado. Faltan ${estadoActualizado?.faltanPorPriorizar ?? 0} persona(s).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No pude guardar la Mesa de Choco: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _crearOAbrirItinerario() async {
    final grupoId = _grupoId;
    if (grupoId == null) return;
    setState(() => _guardando = true);
    try {
      final itinerario = await _itinerarioService.crearItinerario(
        nombre: 'Itinerario ${widget.nombreViaje ?? nombreLegibleDestino(widget.destinoKey)}',
        grupoViajeId: grupoId,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResumenActividadesScreen(
            viajeId: widget.viajeId,
            itinerarioId: itinerario.id,
            nombreViaje: widget.nombreViaje,
            destinoKey: widget.destinoKey,
            actividadesElegidas: const [],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Todavía no se puede crear el itinerario: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = _estado;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mesa de Choco', style: AppFonts.title(17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [IconButton(onPressed: _cargarTodo, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            if (_bannerPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: BackendImage(source: _bannerPath!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(widget.nombreViaje ?? nombreLegibleDestino(widget.destinoKey), style: AppFonts.display(23)),
            const SizedBox(height: 8),
            Text(
              'Aquí el grupo vota las categorías. Ese ranking se guarda en backend y suma puntaje a las actividades antes del knapsack.',
              style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.70), height: 1.38),
            ),
            const SizedBox(height: 18),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              _InfoBox(icon: Icons.error_outline_rounded, text: _error!, color: Colors.orange.shade700)
            else if (estado == null)
              _InfoBox(icon: Icons.info_outline_rounded, text: 'No hay estado de priorización para este viaje.', color: AppColors.primaryDark)
            else ...[
              _InfoBox(
                icon: _listoGrupo ? Icons.check_circle_rounded : Icons.groups_rounded,
                text: _mensajeEstado(estado),
                color: _listoGrupo ? Colors.green.shade700 : AppColors.primaryDark,
              ),
              const SizedBox(height: 18),
              Text('Tu ranking', style: AppFonts.title(16)),
              const SizedBox(height: 8),
              if (_ranking.isEmpty)
                _RankingVacio(puedeEditar: _puedeEditar)
              else
                ...List.generate(_ranking.length, (i) {
                  final c = _ranking[i];
                  return _CategoriaRow(
                    categoria: c,
                    posicion: i + 1,
                    selected: true,
                    onTap: () => _quitar(c),
                  );
                }),
              const SizedBox(height: 20),
              Text('Categorías disponibles', style: AppFonts.title(15)),
              const SizedBox(height: 8),
              if (_disponibles.isEmpty)
                Text(
                  _puedeEditar ? 'No hay más categorías por agregar.' : 'Tu voto ya quedó guardado.',
                  style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.62)),
                )
              else
                ..._disponibles.map((c) => _CategoriaRow(
                      categoria: c,
                      posicion: null,
                      selected: false,
                      onTap: () => _agregar(c),
                    )),
              const SizedBox(height: 24),
              if (_listoGrupo)
                _PrimaryAction(
                  loading: _guardando,
                  label: 'Crear o ver itinerario',
                  icon: Icons.map_rounded,
                  onPressed: _crearOAbrirItinerario,
                )
              else if (_usuarioYaPriorizo)
                _InfoBox(
                  icon: Icons.hourglass_top_rounded,
                  text: 'Tu voto está guardado. Faltan ${estado.faltanPorPriorizar} persona(s) por pasar por la Mesa de Choco.',
                  color: AppColors.text.withValues(alpha: 0.58),
                )
              else
                _PrimaryAction(
                  loading: _guardando,
                  label: 'Guardar mi voto',
                  icon: Icons.how_to_vote_rounded,
                  onPressed: _guardarYContinuar,
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _mensajeEstado(PriorizacionCategoriasEstado estado) {
    if (estado.listoParaItinerario) return 'Todos ya votaron en la Mesa de Choco. Puedes generar el itinerario real del viaje.';
    if (estado.usuarioActualPriorizo) return 'Tu voto ya fue guardado. Han votado ${estado.participantesPriorizados} de ${estado.totalParticipantes}.';
    if (estado.usuarioActualPuedePriorizar) return 'Es tu turno de votar. Ordena las categorías según lo que más quieres para este viaje.';
    return 'Esperando a que el grupo complete los pasos anteriores.';
  }
}

class _CategoriaRow extends StatelessWidget {
  final CategoriaPriorizacionModel categoria;
  final int? posicion;
  final bool selected;
  final VoidCallback onTap;

  const _CategoriaRow({required this.categoria, required this.posicion, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.outlineSoft),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: selected ? AppColors.primaryDark : AppColors.creamLight,
                  child: Text(
                    posicion == null ? '+' : '$posicion',
                    style: AppFonts.label(12, weight: FontWeight.w900).copyWith(color: selected ? Colors.white : AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(categoria.nombre, style: AppFonts.label(14, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${categoria.cantidadActividadesSeleccionadas} actividad(es) seleccionadas por el grupo',
                        style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.60)),
                      ),
                    ],
                  ),
                ),
                Icon(selected ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded, color: AppColors.primaryDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RankingVacio extends StatelessWidget {
  final bool puedeEditar;
  const _RankingVacio({required this.puedeEditar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Text(
        puedeEditar ? 'Toca categorías abajo para armar tu ranking.' : 'No hay ranking para mostrar.',
        textAlign: TextAlign.center,
        style: AppFonts.body(13, color: AppColors.text.withValues(alpha: 0.64)),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoBox({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppFonts.body(13.2, height: 1.35))),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryAction({required this.loading, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 20),
        label: Text(label, style: AppFonts.label(15, weight: FontWeight.w900).copyWith(color: Colors.white)),
      ),
    );
  }
}
