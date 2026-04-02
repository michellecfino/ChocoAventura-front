import 'package:flutter/material.dart';
import '../features/home/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/itinerario/screens/ItinerarioScreen.dart';
import '../features/itinerario/screens/ExploracionScreen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/itinerario': (context) => const ItinerarioScreen(itinerarioId: 1),
  '/explorar': (context) => const ExploracionScreen(),
};