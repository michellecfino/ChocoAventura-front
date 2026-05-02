import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import 'main_shell.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const MainShell(),
  '/login': (context) => const LoginScreen(),
  '/legacy-home': (context) => const HomeScreen(),
};