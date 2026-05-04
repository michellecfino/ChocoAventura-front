import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/assets/asset_resolver.dart';
import 'package:choco/core/widgets/destino_visual.dart';
import 'package:choco/features/itinerario/screens/ItinerarioScreen.dart';
import 'package:choco/features/viajes/data/viajes_mock_data.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:flutter/material.dart';

/// Lista de viajes con itinerario listo; los demás van a sección secundaria.
class ItinerarioHubScreen extends StatefulWidget {
  const ItinerarioHubScreen({super.key});

  @override
  State<ItinerarioHubScreen> createState() => _ItinerarioHubScreenState();
}

class _ItinerarioHubScreenState extends State<ItinerarioHubScreen> {
  final Map<int, String> _banner = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await AssetResolver.instance();
      final m = <int, String>{};
      for (final v in kViajesMockRicos) {
        if (v.id != null) {
          m[v.id!] = r.resolveDestinoImage(v.destinoKey);
        }
      }
      if (mounted) {
        setState(() {
          _banner.addAll(m);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _itinerarioListo(GrupoViajeModel v) {
    return v.itinerarioEstado == 'Listo' || v.itinerarioEstado == 'En viaje';
  }

  bool _enPreparacion(GrupoViajeModel v) {
    return v.itinerarioEstado == 'En construcción';
  }

  String _cta(GrupoViajeModel v, {required bool listo}) {
    if (listo) return 'Ver itinerario';
    return 'Continuar en Viajes';
  }

  Widget _cardViaje(
    BuildContext context,
    GrupoViajeModel v, {
    required bool listo,
  }) {
    final b = v.id != null ? _banner[v.id!] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: listo
              ? () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ItinerarioScreen(
                        itinerarioId: v.id ?? 1,
                        destinoKey: v.destinoKey,
                      ),
                    ),
                  )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Este viaje sigue en preparación. Ábrelo en la pestaña Viajes para explorar o seguir creándolo.',
                        style: AppFonts.body(14),
                      ),
                    ),
                  );
                },
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: b != null
                    ? Image.asset(
                        b,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => DestinoCoverDecorada(
                          titulo: v.destinoNombre,
                          height: 96,
                        ),
                      )
                    : DestinoCoverDecorada(titulo: v.destinoNombre, height: 96),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.nombreViaje, style: AppFonts.title(15)),
                      const SizedBox(height: 4),
                      Text(
                        '${v.fechaInicio ?? '—'} → ${v.fechaFin ?? '—'}',
                        style: AppFonts.body(12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listo ? 'Itinerario: ${v.itinerarioEstado}' : 'Plan en preparación',
                        style: AppFonts.label(11.5, weight: FontWeight.w800).copyWith(color: AppColors.primaryDark),
                      ),
                      if (listo && (v.proximaActividadTexto != null && v.proximaActividadTexto!.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Siguiente: ${v.proximaActividadTexto}',
                          style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.78)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!listo) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Choco está armando el plan con lo que el grupo eligió.',
                          style: AppFonts.body(11.5, color: AppColors.text.withValues(alpha: 0.72)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonal(
                          onPressed: listo
                              ? () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => ItinerarioScreen(
                                        itinerarioId: v.id ?? 1,
                                        destinoKey: v.destinoKey,
                                      ),
                                    ),
                                  )
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Abajo elige la pestaña Viajes para seguir con «${v.nombreViaje}».',
                                        style: AppFonts.body(14),
                                      ),
                                    ),
                                  );
                                },
                          child: Text(_cta(v, listo: listo), style: AppFonts.label(12.5, weight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final viajes = kViajesMockRicos;
    final listos = viajes.where(_itinerarioListo).toList();
    final prep = viajes.where((v) => !_itinerarioListo(v) && _enPreparacion(v)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, top + 14, AppSpacing.md, 8),
              child: Column(
                children: [
                  Center(child: Text('Itinerario', style: AppFonts.display(22))),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Planes por viaje, con fechas y siguiente paso',
                      textAlign: TextAlign.center,
                      style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.78)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            ),
          if (!_loading && listos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.outlineSoft),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 44, color: AppColors.primary.withValues(alpha: 0.85)),
                        const SizedBox(height: 12),
                        Text(
                          'Aún no tienes itinerarios listos',
                          textAlign: TextAlign.center,
                          style: AppFonts.title(17),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Explora actividades y Choco armará el plan contigo.',
                          textAlign: TextAlign.center,
                          style: AppFonts.body(14, height: 1.45, color: AppColors.text.withValues(alpha: 0.78)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_loading && listos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 6),
                child: Text('Itinerarios listos', style: AppFonts.title(16)),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, prep.isEmpty ? 100 : 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _cardViaje(context, listos[i], listo: true),
                  childCount: listos.length,
                ),
              ),
            ),
          ],
          if (!_loading && prep.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 16, AppSpacing.md, 6),
                child: Text('En preparación', style: AppFonts.title(15).copyWith(color: AppColors.text.withValues(alpha: 0.85))),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _cardViaje(context, prep[i], listo: false),
                  childCount: prep.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
