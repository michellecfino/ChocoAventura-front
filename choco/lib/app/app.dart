import 'package:choco/core/widgets/mobile_app_frame.dart';
import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class ChocoAventuraApp extends StatelessWidget {
  const ChocoAventuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'ChocoAventura',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: appRoutes,
      builder: (context, child) => MobileAppFrame(child: child),
    );
  }
}