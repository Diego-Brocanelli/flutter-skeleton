import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/core/router/app_router.dart';
import '../../../lib/src/features/home/presentation/pages/home_page.dart';

// O que testamos aqui: que a NOSSA configuração de rotas (o mapeamento
// path -> widget) está correta — a rota "/" deve levar até a HomePage.
//
// O que NÃO testamos: parsing de URL, histórico de navegação, ou qualquer
// outro comportamento interno do go_router. Isso é responsabilidade do
// pacote e já está coberto pelos testes dele — testar de novo aqui seria
// duplicar esforço testando código de terceiros.
void main() {
  testWidgets('rota inicial "/" exibe a HomePage', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    expect(find.byType(HomePage), findsOneWidget);
  });
}