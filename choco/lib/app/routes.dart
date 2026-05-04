import 'package:choco/features/actividades/screens/explorar_actividades_swipe_screen.dart';
import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'main_shell.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const MainShell(),
  '/login': (context) => const LoginScreen(),
  '/legacy-home': (context) => const HomeScreen(),
  '/explorar-actividades': (context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    final args = raw is ExplorarActividadesArgs
        ? raw
        : const ExplorarActividadesArgs(destinoKey: 'cartagena');
    return ExplorarActividadesSwipeScreen(
      destinoKey: args.destinoKey,
      viajeId: args.viajeId,
      preferenciasTags: args.preferenciasTags,
      nombreViaje: args.nombreViaje,
    );
  },
};