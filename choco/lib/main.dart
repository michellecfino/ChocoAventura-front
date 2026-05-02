import 'package:choco/app/app.dart';
import 'package:choco/features/gastos/choco_opener.dart';
import 'package:choco/features/gastos/widgets/choco_assistant_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _cargarEnvOpcional();

  setGlobalChocoOpener(
    (ctx, service, onActualizado) => mostrarAsistenteGlobalChoco(
      ctx,
      service: service,
      onActualizado: onActualizado,
    ),
  );

  runApp(const ChocoAventuraApp());
}

Future<void> _cargarEnvOpcional() async {
  try {
    await dotenv.load(fileName: 'assets/.env');
    return;
  } catch (_) {}

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Sin archivo .env la app sigue funcionando (mapas y claves opcionales).
  }
}
