import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
};