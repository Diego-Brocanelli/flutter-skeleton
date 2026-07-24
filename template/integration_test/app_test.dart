import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__PACKAGE_NAME__/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test - App Flow', () {
    testWidgets('deve abrir o app e mostrar tela inicial', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Flutter Skeleton'), findsOneWidget);
      expect(find.textContaining('pacotes configurados'), findsOneWidget);
    });
  });
}
