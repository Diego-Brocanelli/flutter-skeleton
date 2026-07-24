import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:__PACKAGE_NAME__/src/features/home/presentation/widgets/home_header_widget.dart';

void main() {
  testWidgets('HomeHeaderWidget exibe a mensagem recebida', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeHeaderWidget(message: 'Bem-vindo ao Flutter Skeleton!'),
      ),
    );

    expect(find.text('Bem-vindo ao Flutter Skeleton!'), findsOneWidget);
  });
}
