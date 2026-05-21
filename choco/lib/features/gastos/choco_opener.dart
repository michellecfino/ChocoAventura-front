import 'package:choco/app/app.dart';
import 'package:choco/features/gastos/services/gastos_service.dart';
import 'package:flutter/material.dart';

typedef GlobalChocoOpenerFn = void Function(
  BuildContext context,
  GastosService service,
  VoidCallback onActualizado,
);

GlobalChocoOpenerFn? _globalChocoOpener;

/// Registrado en [main] para evitar imports circulares (formularios → asistente).
void setGlobalChocoOpener(GlobalChocoOpenerFn fn) => _globalChocoOpener = fn;

/// Abre el asistente global usando el [rootNavigatorKey] tras cerrar modales.
void openGlobalChocoAssistant({
  required GastosService service,
  required VoidCallback onActualizado,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = rootNavigatorKey.currentContext;
    final fn = _globalChocoOpener;
    if (ctx == null || fn == null) return;
    fn(ctx, service, onActualizado);
  });
}
