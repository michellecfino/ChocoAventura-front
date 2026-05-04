import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart' show AssetResolver, nombreLegibleDestino;
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/features/viajes/screens/mesa_choco_screen.dart';
import 'package:flutter/material.dart';

/// Tras explorar actividades: resumen, estado del grupo (demo) y acceso a Mesa.
class EsperaGrupoExploracionScreen extends StatefulWidget {
  final String destinoKey;
  final String? viajeId;
  final String? nombreViaje;
  final int planesInteresantes;

  /// Cuando es true el usuario actual era el último en explorar:
  /// todos ya terminaron → Mesa de Choco habilitada de inmediato.
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

  @override
  void initState() {
    super.initState();
    _cargarBanner();
  }

  Future<void> _cargarBanner() async {
    try {
      final r = await AssetResolver.instance();
      final p = r.resolveDestinoImage(widget.destinoKey);
      if (mounted) setState(() => _banner = p);
    } catch (_) {}
  }

  GrupoViajeModel? get _viaje {
    final id = int.tryParse(widget.viajeId ?? '');
    if (id == null) return null;
    try {
      return kViajesMockRicos.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  int get _total => _viaje?.participantes ?? 5;

  List<ParticipanteMock> get _participantes {
    final viaje = _viaje;
    if (viaje?.participantesList != null && viaje!.participantesList!.isNotEmpty) {
      if (widget.esUltimoEnVotar) {
        return viaje.participantesList!
            .map((p) => ParticipanteMock(nombre: p.nombre, listo: true))
            .toList();
      }
      return viaje.participantesList!;
    }
    final listos = widget.esUltimoEnVotar ? _total : (_total - 1).clamp(1, _total);
    return List.generate(
      _total,
      (i) => ParticipanteMock(nombre: 'Persona ${i + 1}', listo: i < listos),
    );
  }

  bool get _mesaHabilitada {
    if (widget.esUltimoEnVotar) return true;
    return _participantes.every((p) => p.listo);
  }

  int get _listosCount => _participantes.where((p) => p.listo).length;

  void _irAMesa({bool forzar = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MesaChocoScreen(
          viajeId: widget.viajeId,
          nombreViaje: widget.nombreViaje ?? _viaje?.nombreViaje,
          destinoKey: widget.destinoKey,
          forzarConVotosActuales: forzar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final participantes = _participantes;
    final listos = _listosCount;
    final total = _total;
    final faltanN = total - listos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Estado del grupo', style: AppFonts.title(17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        children: [
          // ── Imagen destino (compacta) ───────────────────────────────────────
          if (_banner != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.asset(
                  _banner!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, e, s) => Container(
                    color: AppColors.primaryDark,
                    alignment: Alignment.center,
                    child: Text(
                      nombreLegibleDestino(widget.destinoKey),
                      style: AppFonts.display(24)
                          .copyWith(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Nombre viaje ────────────────────────────────────────────────────
          Text(
            widget.nombreViaje?.trim().isNotEmpty == true
                ? widget.nombreViaje!.trim()
                : nombreLegibleDestino(widget.destinoKey),
            style: AppFonts.display(22),
          ),
          const SizedBox(height: 10),

          // ── Mensaje contextual (compacto) ───────────────────────────────────
          if (widget.esUltimoEnVotar)
            _MensajeCompacto(
              icon: '🎉',
              texto: '¡Listo! Choco ya tiene los votos del grupo.',
              color: Colors.green.shade600,
            )
          else
            _MensajeCompacto(
              icon: '⏳',
              texto: faltanN > 0
                  ? 'Faltan $faltanN de $total personas por explorar.'
                  : '¡Todo el grupo ya exploró! La Mesa de Choco está lista.',
              color: faltanN > 0
                  ? AppColors.text.withValues(alpha: 0.65)
                  : Colors.green.shade600,
            ),

          const SizedBox(height: 18),

          // ── Barra de progreso ───────────────────────────────────────────────
          _GrupoProgressBar(listos: listos, total: total),
          const SizedBox(height: 14),

          // ── Lista de participantes ──────────────────────────────────────────
          Text('Participantes', style: AppFonts.label(13, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...participantes.map((p) => _FilaParticipante(nombre: p.nombre, listo: p.listo)),

          const SizedBox(height: 24),

          // ── CTA Principal: Mesa de Choco ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _mesaHabilitada
                    ? AppColors.primaryDark
                    : AppColors.outlineSoft,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.outlineSoft,
                disabledForegroundColor: AppColors.text.withValues(alpha: 0.40),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _mesaHabilitada ? () => _irAMesa() : null,
              icon: const Icon(Icons.table_restaurant_rounded, size: 20),
              label: Text(
                'Ir a la Mesa de Choco',
                style: AppFonts.label(15, weight: FontWeight.w900)
                    .copyWith(color: Colors.white),
              ),
            ),
          ),

          if (!_mesaHabilitada) ...[
            const SizedBox(height: 6),
            Text(
              'Disponible cuando todos terminen de explorar.',
              style: AppFonts.body(12.5,
                  color: AppColors.text.withValues(alpha: 0.60)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _irAMesa(forzar: true),
                child: Text(
                  'Continuar con votos actuales',
                  style: AppFonts.label(13, weight: FontWeight.w700),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text(
                'Volver al inicio',
                style: AppFonts.label(14, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

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
          Expanded(
            child: Text(texto, style: AppFonts.body(13.5, height: 1.35)),
          ),
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
            Text(
              '$listos de $total ya exploraron',
              style: AppFonts.label(13, weight: FontWeight.w800)
                  .copyWith(color: AppColors.primaryDark),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: AppFonts.body(12.5,
                  color: AppColors.text.withValues(alpha: 0.65)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.outlineSoft,
            color: listos >= total ? Colors.green.shade600 : AppColors.primary,
          ),
        ),
      ],
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
              border: Border.all(
                color: listo ? Colors.green.shade300 : AppColors.outlineSoft,
              ),
            ),
            child: Icon(
              listo ? Icons.check_rounded : Icons.hourglass_top_rounded,
              size: 15,
              color: listo
                  ? Colors.green.shade700
                  : AppColors.text.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(nombre, style: AppFonts.body(14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: listo ? Colors.green.shade50 : AppColors.creamLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    listo ? Colors.green.shade200 : AppColors.outlineSoft,
              ),
            ),
            child: Text(
              listo ? 'Listo ✓' : 'Pendiente',
              style: AppFonts.label(11, weight: FontWeight.w700).copyWith(
                color: listo
                    ? Colors.green.shade700
                    : AppColors.text.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
