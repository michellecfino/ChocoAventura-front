import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class ChocoAventuraApp extends StatelessWidget {
  const ChocoAventuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( //contenedor principal de app flutter con estilo material design
      title: 'ChocoAventura',
      theme: appTheme,
      initialRoute: '/',
      routes: appRoutes,
    );
  }
}