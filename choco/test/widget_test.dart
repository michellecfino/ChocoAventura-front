import 'package:flutter_test/flutter_test.dart';
import 'package:choco/app/app.dart';

void main() {
  testWidgets('La app carga la pantalla inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const ChocoAventuraApp());

    expect(find.text('ChocoAventura'), findsOneWidget);
    expect(find.text('Ir a login'), findsOneWidget);
  });
}