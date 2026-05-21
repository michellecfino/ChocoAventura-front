import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/core/services/user_session.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Abre el modal de auth centrado como popup flotante.
/// [onSuccess] se llama tras un login/registro exitoso.
Future<void> abrirAuthEnSheet(
  BuildContext context, {
  VoidCallback? onSuccess,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _AuthDialog(onSuccess: onSuccess),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog container
// ─────────────────────────────────────────────────────────────────────────────
class _AuthDialog extends StatelessWidget {
  final VoidCallback? onSuccess;

  const _AuthDialog({this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _AuthDialogContent(onSuccess: onSuccess),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog content with tabs
// ─────────────────────────────────────────────────────────────────────────────
class _AuthDialogContent extends StatelessWidget {
  final VoidCallback? onSuccess;

  const _AuthDialogContent({this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 10, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu cuenta', style: AppFonts.display(22)),
                      const SizedBox(height: 2),
                      Text(
                        'Accede o crea tu perfil de viajero',
                        style: AppFonts.body(
                          13,
                          color: AppColors.text.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.text.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Segmented control ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: AppColors.creamLight,
              borderRadius: BorderRadius.circular(16),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.text.withValues(alpha: 0.5),
                labelStyle: AppFonts.label(13.5, weight: FontWeight.w800),
                unselectedLabelStyle: AppFonts.label(13.5, weight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Iniciar sesión'),
                  Tab(text: 'Registrarse'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // ── Forms ──────────────────────────────────────────────────────
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _AuthForm(modoRegistro: false, onSuccess: onSuccess),
                _AuthForm(modoRegistro: true, onSuccess: onSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth form (login / register)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthForm extends StatefulWidget {
  final bool modoRegistro;
  final VoidCallback? onSuccess;

  const _AuthForm({required this.modoRegistro, this.onSuccess});

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> with AutomaticKeepAliveClientMixin {
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _nombre = TextEditingController();
  bool _ocultarPass = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _correo.dispose();
    _pass.dispose();
    _nombre.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppFonts.label(13, weight: FontWeight.w600)
            .copyWith(color: AppColors.text.withValues(alpha: 0.65)),
        filled: true,
        fillColor: AppColors.creamLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.text.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.55),
            width: 1.8,
          ),
        ),
      );

  Future<void> _submit() async {
    setState(() => _error = null);

    final session = UserSession();
    AuthResult result;

    if (widget.modoRegistro) {
      result = await session.register(
        _nombre.text,
        _correo.text,
        _pass.text,
      );
    } else {
      result = await session.login(_correo.text, _pass.text);
    }

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      case AuthError(:final message):
        setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: UserSession(),
      builder: (context, child) {
        final loading = UserSession().loading;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (widget.modoRegistro) ...[
              TextField(
                controller: _nombre,
                style: AppFonts.body(15),
                decoration: _dec('Tu nombre o apodo'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              style: AppFonts.body(15),
              decoration: _dec('Correo electrónico'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pass,
              obscureText: _ocultarPass,
              style: AppFonts.body(15),
              onSubmitted: (_) => _submit(),
              decoration: _dec('Contraseña').copyWith(
                suffixIcon: IconButton(
                  tooltip: _ocultarPass ? 'Mostrar' : 'Ocultar',
                  icon: Icon(
                    _ocultarPass
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.text.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _ocultarPass = !_ocultarPass),
                ),
              ),
            ),

            // ── Error inline ─────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.owe.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.owe.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 17, color: AppColors.owe),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppFonts.body(12.5, color: AppColors.owe, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ── Submit button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.modoRegistro ? 'Crear cuenta' : 'Entrar',
                        style: AppFonts.label(15, weight: FontWeight.w800)
                            .copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tabs body reutilizable (legacy API — mantenido para compatibilidad).
class AuthTabsBody extends StatelessWidget {
  const AuthTabsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthDialogContent(onSuccess: null);
  }
}
