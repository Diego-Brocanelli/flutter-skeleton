import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:__PACKAGE_NAME__/src/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('HomePage deve carregar e exibir conteúdo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomePage())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Flutter Skeleton'), findsOneWidget);
    expect(find.textContaining('Bem-vindo'), findsOneWidget);
    expect(find.textContaining('pacotes configurados'), findsOneWidget);
  });
}
