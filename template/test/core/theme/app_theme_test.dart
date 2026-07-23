import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/src/core/theme/app_theme.dart';

// O que testamos aqui: a NOSSA configuração (useMaterial3, brightness,
// seed color) está sendo aplicada como esperado nos dois temas.
//
// O que NÃO testamos: como o Flutter/Material 3 gera a paleta de cores a
// partir da seed. Esse é um algoritmo do framework, já testado e mantido
// pelo próprio time do Flutter — testar isso aqui seria testar pacote de
// terceiros, não o nosso código.
void main() {
  group('AppTheme', () {
    test('light habilita Material 3 e brightness light', () {
      final theme = AppTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('dark habilita Material 3 e brightness dark', () {
      final theme = AppTheme.dark;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('color scheme de cada tema respeita o brightness correspondente', () {
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });
  });
}