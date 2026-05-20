import 'package:choco/app/colors.dart';
import 'package:choco/app/design_tokens.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/actividades/screens/explorar_actividades_swipe_screen.dart';
import 'package:choco/features/viajes/models/UnirseGrupoDTO.dart';
import 'package:choco/features/viajes/models/categoria.dart';
import 'package:choco/features/viajes/models/grupo_viaje_model.dart';
import 'package:choco/features/viajes/services/viajes_service.dart';
import 'package:flutter/material.dart';

class UnirseViajeCodigoScreen extends StatefulWidget {
  const UnirseViajeCodigoScreen({super.key});

  @override
  State<UnirseViajeCodigoScreen> createState() => _UnirseViajeCodigoScreenState();
}

class _UnirseViajeCodigoScreenState extends State<UnirseViajeCodigoScreen> {
  final _codigoCtrl = TextEditingController();
  final _presupuestoCtrl = TextEditingController();
  final _service = const ViajesService();

  GrupoViajeModel? _viajeValidado;
  List<Categoria> _categorias = <Categoria>[];
  final Set<int> _categoriasSeleccionadas = <int>{};
  bool _validando = false;
  bool _uniendo = false;
  bool _yaSolicitoUnion = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _presupuestoCtrl.dispose();
    super.dispose();
  }

  Future<void> _validarCodigo() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      setState(() => _error = 'Ingresa el código del viaje.');
      return;
    }
    setState(() {
      _validando = true;
      _error = null;
      _viajeValidado = null;
      _categoriasSeleccionadas.clear();
      _yaSolicitoUnion = false;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.validarCodigoInvitacion(codigo),
        _service.getCategorias(),
      ]);
      if (!mounted) return;
      setState(() {
        _viajeValidado = results[0] as GrupoViajeModel;
        _categorias = results[1] as List<Categoria>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No encontré un viaje con ese código. Revisa que esté bien escrito.');
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  Future<void> _unirse() async {
    if (_uniendo || _yaSolicitoUnion) return;
    final usuarioId = UserSession().user?.id;
    final viaje = _viajeValidado;
    if (usuarioId == null) {
      setState(() => _error = 'Debes iniciar sesión para unirte a un viaje.');
      return;
    }
    if (viaje?.id == null) {
      setState(() => _error = 'Primero valida el código del viaje.');
      return;
    }
    final presupuesto = double.tryParse(
      _presupuestoCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'),
    );
    if (presupuesto == null || presupuesto <= 0) {
      setState(() => _error = 'Ingresa un presupuesto válido.');
      return;
    }
    setState(() {
      _uniendo = true;
      _yaSolicitoUnion = true;
      _error = null;
    });
    try {
      final unido = await _service.unirseAGrupo(
        UnirseGrupoDTO(
          usuarioId: usuarioId,
          grupoId: viaje!.id,
          codigoInvitacion: _codigoCtrl.text.trim(),
          categoriasIds: _categoriasSeleccionadas.toList(),
          presupuesto: presupuesto,
          personasACargo: 1,
        ),
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, bool>(
        MaterialPageRoute<void>(
          builder: (_) => ExplorarActividadesSwipeScreen(
            destinoKey: unido.destinoKey,
            viajeId: '${unido.id}',
            nombreViaje: unido.nombreViaje,
          ),
        ),
        result: true,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final yaPertenece = msg.contains('ya') ||
          msg.contains('pertenec') ||
          msg.contains('unido') ||
          msg.contains('409');
      if (yaPertenece && viaje != null) {
        await Navigator.of(context).pushReplacement<void, bool>(
          MaterialPageRoute<void>(
            builder: (_) => ExplorarActividadesSwipeScreen(
              destinoKey: viaje.destinoKey,
              viajeId: '${viaje.id}',
              nombreViaje: viaje.nombreViaje,
            ),
          ),
          result: true,
        );
        return;
      }
      setState(() {
        _yaSolicitoUnion = false;
        _error = 'No pude unirte al viaje. Detalle: $e';
      });
    } finally {
      if (mounted) setState(() => _uniendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viaje = _viajeValidado;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Unirse a viaje', style: AppFonts.title(17)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Código de invitación', style: AppFonts.display(23)),
          const SizedBox(height: 8),
          Text(
            'Pega el código que te compartieron. Luego Choco te pedirá solo tu presupuesto y tus categorías favoritas para este viaje.',
            style: AppFonts.body(13.5, height: 1.38, color: AppColors.text.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codigoCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Código del viaje',
              hintText: 'Ej: CHOCO-12',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              prefixIcon: const Icon(Icons.key_rounded),
            ),
            onChanged: (_) {
              if (_viajeValidado != null) {
                setState(() {
                  _viajeValidado = null;
                  _categoriasSeleccionadas.clear();
                  _error = null;
                });
              }
            },
            onSubmitted: (_) => _validarCodigo(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _validando ? null : _validarCodigo,
              icon: _validando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded),
              label: Text(_validando ? 'Validando...' : 'Validar código', style: AppFonts.label(14, weight: FontWeight.w900)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _InfoBox(text: _error!, color: Colors.orange.shade700, icon: Icons.error_outline_rounded),
          ],
          if (viaje != null) ...[
            const SizedBox(height: 20),
            _ViajeValidadoCard(viaje: viaje),
            const SizedBox(height: 20),
            Text('Tu presupuesto', style: AppFonts.title(16)),
            const SizedBox(height: 8),
            TextField(
              controller: _presupuestoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Presupuesto por persona',
                hintText: 'Ej: 500000',
                prefixText: r'$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 18),
            Text('Tus categorías favoritas', style: AppFonts.title(16)),
            const SizedBox(height: 8),
            if (_categorias.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((cat) {
                  final selected = _categoriasSeleccionadas.contains(cat.id);
                  return ChoiceChip(
                    label: Text(cat.nombre),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _categoriasSeleccionadas.remove(cat.id);
                        } else {
                          _categoriasSeleccionadas.add(cat.id);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.22),
                    backgroundColor: AppColors.creamLight,
                    labelStyle: AppFonts.label(12.5, weight: selected ? FontWeight.w800 : FontWeight.w600),
                    shape: StadiumBorder(
                      side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineSoft),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _uniendo ? null : _unirse,
                icon: _uniendo
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.swipe_rounded),
                label: Text(_uniendo ? 'Uniéndote...' : 'Unirme e iniciar swipe', style: AppFonts.label(15, weight: FontWeight.w900).copyWith(color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViajeValidadoCard extends StatelessWidget {
  final GrupoViajeModel viaje;
  const _ViajeValidadoCard({required this.viaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(Icons.travel_explore_rounded, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(viaje.nombreViaje, style: AppFonts.label(15, weight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(viaje.ciudadDepartamento, style: AppFonts.body(12.5, color: AppColors.text.withValues(alpha: 0.70))),
                const SizedBox(height: 3),
                Text('${viaje.participantes} participante(s)', style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.58))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _InfoBox({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppFonts.body(13, height: 1.35))),
        ],
      ),
    );
  }
}
