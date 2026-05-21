import 'dart:async';
import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart' show AssetResolver, nombreLegibleDestino;
import 'package:choco/core/services/user_session.dart';
import 'package:choco/core/widgets/backend_image.dart';
import 'package:choco/features/asistente/services/choco_assistant_service.dart';
import 'package:choco/features/viajes/screens/mesa_choco_screen.dart';
import 'package:choco/features/viajes/services/priorizacion_categorias_service.dart';
import 'package:choco/features/viajes/services/viajes_service.dart';
import 'package:flutter/material.dart';

/// Estado real del viaje después del swipe individual.
///
/// Esta pantalla ya no usa mocks: consulta el backend con el `grupoViajeId`
/// actual y decide, para el usuario que inició sesión, si debe explorar,
/// esperar, priorizar o puede entrar a Mesa de Choco.
class EsperaGrupoExploracionScreen extends StatefulWidget {
  final String destinoKey;
  final String? viajeId;
  final String? nombreViaje;
  final int planesInteresantes;
  final bool esUltimoEnVotar;

  const EsperaGrupoExploracionScreen({
    super.key,
    required this.destinoKey,
    this.viajeId,
    this.nombreViaje,
    required this.planesInteresantes,
    this.esUltimoEnVotar = false,
  });

  @override
  State<EsperaGrupoExploracionScreen> createState() => _EsperaGrupoExploracionScreenState();
}

class _EsperaGrupoExploracionScreenState extends State<EsperaGrupoExploracionScreen> {
  String? _banner;
  EstadoExploracionGrupo? _estado;
  PriorizacionCategoriasEstado? _estadoPrioridades;
  bool _cargando = true;
  String? _error;
  Timer? _refreshTimer;

  int? get _grupoId => int.tryParse(widget.viajeId ?? '');
  int? get _usuarioId => UserSession().user?.id;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _cargarEstados();
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
    await Future.wait([_cargarBanner(), _cargarEstados()]);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarBanner() async {
    try {
      final r = await AssetResolver.instance();
      final p = r.resolveDestinoImage(widget.destinoKey);
      if (mounted) setState(() => _banner = p);
    } catch (_) {}
  }

  Future<void> _cargarEstados() async {
    final grupoId = _grupoId;
    if (grupoId == null) {
      if (mounted) setState(() => _error = 'No encontré el identificador de este viaje.');
      return;
    }
    try {
      final estado = await const ViajesService().obtenerEstadoExploracion(
        grupoViajeId: grupoId,
        usuarioId: _usuarioId,
      );
      PriorizacionCategoriasEstado? prioridades;
      if (estado?.todosLosPerfilesListos == true) {
        prioridades = await const PriorizacionCategoriasService().cargarEstado(
          grupoViajeId: grupoId,
          usuarioId: _usuarioId,
        );
      }
      if (!mounted) return;
      setState(() {
        _estado = estado;
        _estadoPrioridades = prioridades;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'No pude cargar el estado real de este viaje. Revisa el backend.');
    }
  }

  int get _total => _estado?.totalParticipantes ?? 0;
  int get _listosCount => _estado?.perfilesListos ?? 0;
  int get _faltanN => _estado?.faltanPorExplorar ?? 0;
  bool get _exploracionCompleta => _estado?.mesaHabilitada == true;
  bool get _priorizacionCompleta => _estadoPrioridades?.listoParaItinerario == true;
  bool get _mesaHabilitada => _exploracionCompleta && _priorizacionCompleta;
  bool get _usuarioDebeExplorar => _estado?.usuarioActualPuedeExplorar == true;
  bool get _usuarioDebePriorizar => _estadoPrioridades?.usuarioActualPuedePriorizar == true;

  void _irAExplorar() {
    final grupoId = _grupoId;
    if (grupoId == null) return;
    navegarExplorarActividades(
      context,
      destinoKey: widget.destinoKey,
      viajeId: '$grupoId',
      nombreViaje: widget.nombreViaje,
    );
  }

  Future<void> _irAPriorizar() async {
    final grupoId = _grupoId;
    if (grupoId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MesaChocoScreen(
          viajeId: '$grupoId',
          destinoKey: widget.destinoKey,
          nombreViaje: widget.nombreViaje,
        ),
      ),
    );
    if (mounted) _cargarTodo();
  }

  void _irAMesa() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesaChocoScreen(
          viajeId: widget.viajeId,
          nombreViaje: widget.nombreViaje,
          destinoKey: widget.destinoKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Estado del grupo', style: AppFonts.title(17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarTodo,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          children: [
            if (_banner != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: BackendImage(
                    source: _banner!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, e, s) => Container(
                      color: AppColors.primaryDark,
                      alignment: Alignment.center,
                      child: Text(
                        nombreLegibleDestino(widget.destinoKey),
                        style: AppFonts.display(24).copyWith(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.nombreViaje?.trim().isNotEmpty == true ? widget.nombreViaje!.trim() : nombreLegibleDestino(widget.destinoKey),
              style: AppFonts.display(22),
            ),
            const SizedBox(height: 10),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              _MensajeCompacto(icon: '⚠️', texto: _error!, color: Colors.orange.shade700)
            else ...[
              _MensajeCompacto(
                icon: _mesaHabilitada ? '🎉' : (_usuarioDebeExplorar || _usuarioDebePriorizar ? '👉' : '⏳'),
                texto: _mensajePrincipal(),
                color: _mesaHabilitada ? Colors.green.shade600 : AppColors.text.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 18),
              _GrupoProgressBar(listos: _listosCount, total: _total),
              const SizedBox(height: 14),
              Text('Participantes', style: AppFonts.label(13, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...(_estado?.participantes ?? const <ParticipanteEstadoGrupo>[])
                  .map((p) => _FilaParticipante(nombre: p.nombre, listo: p.listo)),
              if (_estadoPrioridades != null) ...[
                const SizedBox(height: 18),
                _PrioridadResumen(estado: _estadoPrioridades!),
              ],
              const SizedBox(height: 24),
              if (_usuarioDebeExplorar) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _irAExplorar,
                    icon: const Icon(Icons.swipe_rounded, size: 20),
                    label: Text('Explorar mis actividades', style: AppFonts.label(15, weight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu exploración es la que falta en este viaje.',
                  style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.60)),
                  textAlign: TextAlign.center,
                ),
              ] else if (_usuarioDebePriorizar) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _irAPriorizar,
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    label: Text('Ir a la Mesa de Choco', style: AppFonts.label(15, weight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu voto en la Mesa de Choco es el que falta para poder generar el itinerario.',
                  style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.60)),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _mesaHabilitada ? AppColors.primaryDark : AppColors.outlineSoft,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.outlineSoft,
                      disabledForegroundColor: AppColors.text.withValues(alpha: 0.40),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _mesaHabilitada ? _irAMesa : null,
                    icon: const Icon(Icons.table_restaurant_rounded, size: 20),
                    label: Text('Ir a la Mesa de Choco', style: AppFonts.label(15, weight: FontWeight.w900).copyWith(color: Colors.white)),
                  ),
                ),
                if (!_mesaHabilitada) ...[
                  const SizedBox(height: 6),
                  Text(
                    _exploracionCompleta ? 'Disponible cuando todos voten en la Mesa de Choco.' : 'Disponible cuando todos terminen de explorar.',
                    style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.60)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text('Volver al inicio', style: AppFonts.label(14, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mensajePrincipal() {
    if (_usuarioDebeExplorar) return 'Falta tu exploración individual. El grupo no puede avanzar hasta que la completes.';
    if (!_exploracionCompleta) return 'Faltan $_faltanN de $_total personas por explorar.';
    if (_usuarioDebePriorizar) return 'Todos exploraron. Ahora falta tu voto en la Mesa de Choco.';
    if (_estadoPrioridades != null && !_estadoPrioridades!.listoParaItinerario) {
      return 'Todos exploraron. Esperando votos de otros participantes en la Mesa de Choco.';
    }
    return '¡Todo el grupo ya exploró y votó! La Mesa de Choco puede generar el itinerario.';
  }
}

class _MensajeCompacto extends StatelessWidget {
  final String icon;
  final String texto;
  final Color color;

  const _MensajeCompacto({
    required this.icon,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: AppFonts.body(13.5, height: 1.35))),
        ],
      ),
    );
  }
}

class _GrupoProgressBar extends StatelessWidget {
  final int listos;
  final int total;

  const _GrupoProgressBar({required this.listos, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? listos / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$listos de $total ya exploraron', style: AppFonts.label(13, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark)),
            Text('${(pct * 100).round()}%', style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.65))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.outlineSoft,
            color: listos >= total && total > 0 ? Colors.green.shade600 : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PrioridadResumen extends StatelessWidget {
  final PriorizacionCategoriasEstado estado;

  const _PrioridadResumen({required this.estado});

  @override
  Widget build(BuildContext context) {
    final listo = estado.listoParaItinerario;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: listo ? Colors.green.withValues(alpha: 0.10) : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        children: [
          Icon(listo ? Icons.check_circle_rounded : Icons.sort_rounded, color: listo ? Colors.green.shade700 : AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              listo
                  ? 'Todos votaron en la Mesa de Choco. El itinerario se puede generar.'
                  : 'Han votado ${estado.participantesPriorizados} de ${estado.totalParticipantes}. Faltan ${estado.faltanPorPriorizar}.',
              style: AppFonts.body(12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  final String nombre;
  final bool listo;

  const _FilaParticipante({required this.nombre, required this.listo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: listo ? Colors.green.shade50 : AppColors.surfaceMuted,
              border: Border.all(color: listo ? Colors.green.shade300 : AppColors.outlineSoft),
            ),
            child: Icon(
              listo ? Icons.check_rounded : Icons.hourglass_top_rounded,
              size: 15,
              color: listo ? Colors.green.shade700 : AppColors.text.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(nombre, style: AppFonts.body(14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: listo ? Colors.green.shade50 : AppColors.creamLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: listo ? Colors.green.shade200 : AppColors.outlineSoft),
            ),
            child: Text(
              listo ? 'Listo ✓' : 'Pendiente',
              style: AppFonts.label(11, weight: FontWeight.w700).copyWith(
                color: listo ? Colors.green.shade700 : AppColors.text.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
