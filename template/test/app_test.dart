import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/main.dart';

// Smoke test: garante que a composição final do app (tema + rotas + DI via
// Riverpod, todos juntos a partir de MyApp) sobe sem erros e chega até a
// tela esperada na rota inicial.
//
// Não repetimos aqui os asserts detalhados de conteúdo da HomePage — isso
// já está coberto em home_page_test.dart. Este teste existe só para pegar
// erros de "encanamento" (ex.: um provider mal configurado que só quebra
// quando tudo é montado junto).
void main() {
  testWidgets('App inicializa e mostra a HomePage na rota inicial', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo ao Template!'), findsOneWidget);
  });
}