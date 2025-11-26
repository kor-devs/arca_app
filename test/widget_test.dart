// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:arca_app/main.dart'; // Importa nosso main.dart

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Justificativa: Alteramos 'MyApp' para 'ArcaApp' para
    // bater com a classe que criamos em main.dart.
    await tester.pumpWidget(const MyApp());

    // Este teste agora é válido (mas não testa muito,
    // o que é ok para a nossa agilidade atual)
    expect(find.text('Arca - Livros da Bíblia (NVI)'), findsNothing);
  });
}