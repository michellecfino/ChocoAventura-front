import 'dart:math' as math;

import 'package:choco/app/colors.dart';
import 'package:choco/app/fonts.dart';
import 'package:choco/features/auth/widgets/auth_modal_sheet.dart';
import 'package:flutter/material.dart';

/// Ruta `/login`: misma experiencia visual que el sheet, centrada y amable.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Iniciar sesión', style: AppFonts.title(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.outlineSoft),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowWarm, blurRadius: 22, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
                        child: Text(
                          'Bienvenido a ChocoAventura',
                          textAlign: TextAlign.center,
                          style: AppFonts.display(21),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          'Entra o regístrate para no perder el hilo de tus aventuras.',
                          textAlign: TextAlign.center,
                          style: AppFonts.body(13.5, color: AppColors.text.withValues(alpha: 0.75), height: 1.4),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, _) {
                          final h = math.min(
                            540.0,
                            MediaQuery.sizeOf(context).height * 0.58,
                          );
                          return SizedBox(height: h, child: const AuthTabsBody());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
