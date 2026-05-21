import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/app/app.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:choco/features/auth/widgets/auth_modal_sheet.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Abre perfil si hay sesión, o el modal de auth si no.
Future<void> abrirPerfil(BuildContext context) {
  if (!UserSession().isLoggedIn) {
    return abrirAuthEnSheet(context);
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PerfilSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Perfil sheet (logged-in state)
// ─────────────────────────────────────────────────────────────────────────────
class _PerfilSheet extends StatelessWidget {
  const _PerfilSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.90,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ListenableBuilder(
          listenable: UserSession(),
          builder: (ctx2, child) {
            final session = UserSession();
            final user = session.user;
            if (user == null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => Navigator.of(ctx).pop(),
              );
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 10),
                _DragHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 10, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Mi perfil', style: AppFonts.display(21))),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.text.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                    children: [
                      _PerfilHeader(user: user),
                      const SizedBox(height: 18),
                      _StatsCard(),
                      const SizedBox(height: 18),
                      _ConfigSection(
                        onCerrarSesion: () {
                          if (Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          }
                          session.logout();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final nav = rootNavigatorKey.currentState;
                            if (nav != null) {
                              nav.pushNamedAndRemoveUntil('/', (route) => false);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _PerfilHeader extends StatelessWidget {
  final UserModel user;

  const _PerfilHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvatarCircle(nombre: user.nombre, size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.nombre, style: AppFonts.display(22)),
              const SizedBox(height: 3),
              Text(
                user.correo,
                style: AppFonts.body(
                  13,
                  color: AppColors.text.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 8),
              _Badge(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '✦ Explorador',
        style: AppFonts.label(11.5, weight: FontWeight.w700)
            .copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(valor: '3', etiqueta: 'Viajes'),
          _VerticalDivider(),
          _StatItem(valor: '\$0', etiqueta: 'Pendiente'),
          _VerticalDivider(),
          _StatItem(valor: '1', etiqueta: 'Itinerario'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _StatItem({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor, style: AppFonts.display(20)),
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: AppFonts.body(12, color: AppColors.text.withValues(alpha: 0.62)),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.outlineSoft);
  }
}

class _ConfigSection extends StatelessWidget {
  final VoidCallback onCerrarSesion;

  const _ConfigSection({required this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline_rounded, 'Mis datos', 'Nombre, correo y apodo'),
      (Icons.tune_rounded, 'Preferencias', 'Destinos y estilo de viaje'),
      (Icons.notifications_none_rounded, 'Notificaciones', 'Avisos de grupo'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuración', style: AppFonts.title(14)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outlineSoft),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final (icon, titulo, sub) = e.value;
              return Column(
                children: [
                  ListTile(
                    onTap: () => ScaffoldMessenger.maybeOf(context)
                        ?.showSnackBar(
                          SnackBar(
                            content: Text(
                              '$titulo próximamente',
                              style: AppFonts.body(14),
                            ),
                          ),
                        ),
                    leading: Icon(icon, color: AppColors.primaryDark, size: 22),
                    title: Text(
                      titulo,
                      style: AppFonts.label(14, weight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      sub,
                      style: AppFonts.body(
                        12,
                        color: AppColors.text.withValues(alpha: 0.58),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.text.withValues(alpha: 0.28),
                      size: 20,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.outlineSoft,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCerrarSesion,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.owe.withValues(alpha: 0.40)),
              foregroundColor: AppColors.owe,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: Text(
              'Cerrar sesión',
              style: AppFonts.label(14, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Public widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Avatar circular con inicial del nombre.
class _AvatarCircle extends StatelessWidget {
  final String nombre;
  final double size;

  const _AvatarCircle({required this.nombre, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          inicial,
          style: AppFonts.display(size * 0.38).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Botón de avatar en el header — público para usar en HomeScreen.
class PerfilAvatarButton extends StatelessWidget {
  final double size;

  const PerfilAvatarButton({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, child) {
        final session = UserSession();
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => abrirPerfil(context),
            child: session.isLoggedIn
                ? _AvatarCircle(nombre: session.nombreDisplay, size: size)
                : _GuestAvatar(size: size),
          ),
        );
      },
    );
  }
}

class _GuestAvatar extends StatelessWidget {
  final double size;

  const _GuestAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.outlineMedium, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWarm,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person_outline_rounded,
        size: size * 0.5,
        color: AppColors.text.withValues(alpha: 0.50),
      ),
    );
  }
}
