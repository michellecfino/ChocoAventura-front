import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:flutter/material.dart';

import '../models/gastos_models.dart';
import '../services/gastos_service.dart';
import '../widgets/registrar_gasto_sheet.dart';

class DetalleGastosViajeScreen extends StatefulWidget {
  final ViajeFinancieroResumen resumen;
  final GastosService service;

  const DetalleGastosViajeScreen({
    super.key,
    required this.resumen,
    required this.service,
  });

  @override
  State<DetalleGastosViajeScreen> createState() => _DetalleGastosViajeScreenState();
}

class _DetalleGastosViajeScreenState extends State<DetalleGastosViajeScreen> {
  late Future<DetalleFinancieroViaje> _detalle;
  final PageController _pageCtrl = PageController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _detalle = widget.service.fetchDetalle(
      idGrupo: widget.resumen.idViaje,
      perfilId: widget.resumen.perfilId,
    );
  }

  void _refrescar() {
    setState(() {
      _detalle = widget.service.fetchDetalle(
        idGrupo: widget.resumen.idViaje,
        perfilId: widget.resumen.perfilId,
      );
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _syncTab(int i) {
    setState(() => _tab = i);
    _pageCtrl.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Gastos del viaje', style: AppFonts.title(15)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'det_manual',
        onPressed: () => mostrarRegistrarGastoSheet(
          context,
          viajePrefijado: widget.resumen,
          service: widget.service,
          alGuardar: _refrescar,
          initialTab: 0,
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        label: Text(
          'Gasto',
          style: AppFonts.label(13, weight: FontWeight.w800).copyWith(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FutureBuilder<DetalleFinancieroViaje>(
        future: _detalle,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('No se pudo cargar el detalle.'));
          }
          final d = snap.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: _HeroBalanceViaje(resumen: widget.resumen, detalle: d),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentCapsule(
                  tab: _tab,
                  onChanged: _syncTab,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _tab = i),
                  children: [
                    _BalanceVisual(resumen: widget.resumen, detalle: d),
                    _ResumenVisual(detalle: d),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Píldoras Balance | Resumen dentro de una cápsula.
class _SegmentCapsule extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;

  const _SegmentCapsule({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowWarm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegChip(
              selected: tab == 0,
              icon: Icons.balance_rounded,
              label: 'Balance',
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegChip(
              selected: tab == 1,
              icon: Icons.pie_chart_outline_rounded,
              label: 'Resumen',
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SegChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AppColors.text.withValues(alpha: selected ? 1 : 0.55)),
              const SizedBox(width: 6),
              Text(label, style: AppFonts.label(12.8, weight: selected ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBalanceViaje extends StatelessWidget {
  final ViajeFinancieroResumen resumen;
  final DetalleFinancieroViaje detalle;

  const _HeroBalanceViaje({required this.resumen, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final neto = resumen.teDeben - resumen.tuDebes;
    final insight = detalle.todoSaldado
        ? 'Todo saldado — ¡gran trabajo!'
        : resumen.tuDebes > resumen.teDeben
            ? 'Sigues debiendo en este viaje'
            : resumen.teDeben > resumen.tuDebes
                ? 'Te tienen que pagar más de lo que debes'
                : 'Balance casi parejo entre el grupo';

    final montoHero =
        detalle.todoSaldado ? '¡Al día!' : formatoCop(neto.abs());

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.primaryDark,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        resumen.nombreViaje,
                        style: AppFonts.title(15).copyWith(color: AppColors.creamLight, height: 1.15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (detalle.todoSaldado)
                          _HeroTag(label: 'Saldado', fg: AppColors.primaryDark, bg: AppColors.creamLight)
                        else ...[
                          if (resumen.tuDebes > 0)
                            _HeroTag(label: 'Debes', fg: Colors.white, bg: AppColors.owe.withValues(alpha: 0.88)),
                          if (resumen.teDeben > 0)
                            _HeroTag(label: 'Te deben', fg: Colors.white, bg: AppColors.owed.withValues(alpha: 0.9)),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _BalanceCirculoRing(
                  linea1: detalle.todoSaldado ? 'Estado' : 'Tu balance',
                  linea2: montoHero,
                  subtitulo: detalle.todoSaldado ? null : (neto >= 0 ? 'A tu favor' : 'Pendiente'),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.creamLight.withValues(alpha: 0.95), size: 17),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight,
                          textAlign: TextAlign.center,
                          style: AppFonts.body(12, color: AppColors.creamLight.withValues(alpha: 0.92), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enfoque circular tipo “medallón” para el saldo principal.
class _BalanceCirculoRing extends StatelessWidget {
  final String linea1;
  final String linea2;
  final String? subtitulo;

  const _BalanceCirculoRing({
    required this.linea1,
    required this.linea2,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              color: Colors.white.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    linea1,
                    style: AppFonts.label(10.5, weight: FontWeight.w800)
                        .copyWith(color: AppColors.creamLight.withValues(alpha: 0.85), letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    linea2,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.amount(linea2.length > 12 ? 15.0 : 18.0)
                        .copyWith(color: AppColors.creamLight, height: 1.05),
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitulo!,
                      style: AppFonts.label(10.5, weight: FontWeight.w700)
                          .copyWith(color: AppColors.creamLight.withValues(alpha: 0.88)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _HeroTag({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppFonts.label(11.5, weight: FontWeight.w800).copyWith(color: fg)),
    );
  }
}

class _BalanceVisual extends StatelessWidget {
  final ViajeFinancieroResumen resumen;
  final DetalleFinancieroViaje detalle;

  const _BalanceVisual({required this.resumen, required this.detalle});

  @override
  Widget build(BuildContext context) {
    if (detalle.todoSaldado) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.85)),
              const SizedBox(height: 16),
              Text('Todo saldado', style: AppFonts.display(22)),
              const SizedBox(height: 10),
              Text(
                'Cuentas claras, aventura lista para el siguiente capítulo.',
                textAlign: TextAlign.center,
                style: AppFonts.body(15, color: AppColors.text.withValues(alpha: 0.82), height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniBalanceCard(
                titulo: 'Tú debes',
                monto: resumen.tuDebes,
                color: AppColors.owe,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniBalanceCard(
                titulo: 'Te deben',
                monto: resumen.teDeben,
                color: AppColors.owed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('A quién le debes', style: AppFonts.title(15)),
        const SizedBox(height: 8),
        if (detalle.personasTuDebes.isEmpty)
          _bloqueVacio('Por aquí no hay deudas pendientes.')
        else
          ...detalle.personasTuDebes.map((p) => _tarjetaPersona(p, acento: AppColors.accentMuted)),
        const SizedBox(height: 18),
        Text('Quién te debe', style: AppFonts.title(15)),
        const SizedBox(height: 8),
        if (detalle.personasTeDeben.isEmpty)
          _bloqueVacio('Nadie te debe en este viaje por ahora.')
        else
          ...detalle.personasTeDeben.map((p) => _tarjetaPersona(p, acento: AppColors.primary)),
      ],
    );
  }

  Widget _bloqueVacio(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      child: Text(msg, style: AppFonts.body(14)),
    );
  }

  Widget _tarjetaPersona(PersonaMonto p, {required Color acento}) {
    final ini = p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceElevated,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.outlineSoft),
          ),
          leading: CircleAvatar(
            backgroundColor: acento.withValues(alpha: 0.22),
            foregroundColor: AppColors.text,
            child: Text(ini, style: AppFonts.label(14, weight: FontWeight.w800)),
          ),
          title: Text(p.nombre, style: AppFonts.label(13.5, weight: FontWeight.w700)),
          trailing: Text(formatoCop(p.monto), style: AppFonts.amount(13.5)),
        ),
      ),
    );
  }
}

class _MiniBalanceCard extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;

  const _MiniBalanceCard({
    required this.titulo,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppFonts.label(11.5, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(formatoCop(monto), style: AppFonts.amount(15)),
        ],
      ),
    );
  }
}

class _ResumenVisual extends StatelessWidget {
  final DetalleFinancieroViaje detalle;

  const _ResumenVisual({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final prog = detalle.presupuestoTotal <= 0
        ? 0.0
        : (detalle.gastado / detalle.presupuestoTotal).clamp(0.0, 1.0);
    final pct = (prog * 100).round();

    final orden = ['Comida', 'Transporte', 'Actividades', 'Hospedaje', 'Otros'];
    final valores = orden.map((k) => detalle.resumenPorCategoria[k] ?? 0.0).toList();
    final totalCat = valores.fold<double>(0, (a, b) => a + b);

    final palette = [
      AppColors.primary,
      AppColors.accentMuted,
      AppColors.owed,
      AppColors.owe,
      AppColors.primaryDark,
      AppColors.accent.withValues(alpha: 0.75),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Row(
          children: [
            Expanded(child: Text('Presupuesto', style: AppFonts.title(16))),
            Icon(Icons.savings_outlined, color: AppColors.primaryDark, size: 26),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
            boxShadow: [BoxShadow(color: AppColors.shadowWarm, blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _metricRow('Presupuesto total', formatoCop(detalle.presupuestoTotal)),
              _metricRow('Has gastado', formatoCop(detalle.gastado)),
              _metricRow('Te queda', formatoCop(detalle.restante)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Presupuesto usado',
                    style: AppFonts.label(12.5, weight: FontWeight.w800),
                  ),
                  Text(
                    '$pct%',
                    style: AppFonts.amount(14).copyWith(color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: prog,
                  minHeight: 11,
                  backgroundColor: AppColors.creamLight,
                  color: prog > 0.85 ? AppColors.owe : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Por categoría', style: AppFonts.title(15)),
        const SizedBox(height: 8),
        if (totalCat > 0)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Donut
                SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(
                    painter: _DonutCategoriasPainter(
                      fractions: [
                        for (var i = 0; i < orden.length; i++)
                          if (valores[i] > 0) valores[i] / totalCat,
                      ],
                      colors: [
                        for (var i = 0; i < orden.length; i++)
                          if (valores[i] > 0) palette[i % palette.length],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Lista con barras
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < orden.length; i++)
                        if (valores[i] > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: palette[i % palette.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(orden[i], style: AppFonts.label(12, weight: FontWeight.w700)),
                                    ),
                                    Text(
                                      formatoCop(valores[i]),
                                      style: AppFonts.amount(11.5).copyWith(
                                        color: AppColors.text.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalCat > 0 ? valores[i] / totalCat : 0,
                                    minHeight: 5,
                                    backgroundColor: AppColors.creamLight,
                                    color: palette[i % palette.length],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Aún no hay gastos por categoría.',
            style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.65)),
          ),
        const SizedBox(height: 18),
        Text('Gastos recientes', style: AppFonts.title(15)),
        const SizedBox(height: 8),
        ...detalle.gastosRecientes.take(4).map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineSoft),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    title: Text(g.descripcion, style: AppFonts.label(13.5, weight: FontWeight.w700)),
                    subtitle: Text(
                      g.categoria,
                      style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.72)),
                    ),
                    trailing: Text(formatoCop(g.monto), style: AppFonts.amount(13)),
                  ),
                ),
              ),
            ),
        Center(
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historial completo se conectará al backend.')),
              );
            },
            child: Text('Ver historial', style: AppFonts.label(14, weight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _metricRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.9), weight: FontWeight.w700),
          ),
          Text(v, style: AppFonts.amount(14.5)),
        ],
      ),
    );
  }
}

/// Dona simple para proporción de categorías (solo segmentos > 0).
class _DonutCategoriasPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;

  _DonutCategoriasPainter({required this.fractions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (fractions.isEmpty || fractions.length != colors.length) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.58;
    var start = -3.14159 / 2;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 3.14159 * 2;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer - inner
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (outer + inner) / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
