import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

// Diferente dos testes em test/, aqui o app roda de verdade (motor de
// renderização real — device, emulador ou build desktop/web), não em
// ambiente simulado. Por isso o foco deve ser em FLUXOS REAIS de ponta a
// ponta (o app sobe, conecta com plugins nativos, navega entre telas de
// verdade), e não em repetir asserts que já são cobertos pelos testes de
// widget em test/ — isso só deixaria a suíte mais lenta sem agregar
// confiança extra.
//
// Chamamos app.main() (em vez de montar MyApp manualmente) para também
// exercitar qualquer inicialização real que existir dentro do main() —
// hoje é só o runApp, mas se no futuro entrar carregamento de .env,
// inicialização de SDK, etc., o teste de integração continua cobrindo
// isso de verdade.
//
// À medida que novos domínios forem criados (via `make new-domain`), o
// ideal é acrescentar aqui fluxos que atravessam mais de uma feature
// (ex.: navegar de Home até Estoque e voltar), não um teste por feature
// isolada — isso já é papel do test/.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fluxo principal do app', () {
    testWidgets('app inicializa e mostra a HomePage', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Flutter Skeleton'), findsOneWidget);
      expect(find.text('Bem-vindo ao Template!'), findsOneWidget);
    });
  });
}