import 'package:flutter_test/flutter_test.dart';
import 'package:__PACKAGE_NAME__/src/features/home/domain/entities/home_entity.dart';

void main() {
  group('HomeEntity', () {
    test('deve criar entidade corretamente', () {
      const entity = HomeEntity(
        welcomeMessage: 'Bem-vindo!',
        configuredPackages: ['Riverpod', 'go_router'],
      );

      expect(entity.welcomeMessage, 'Bem-vindo!');
      expect(entity.configuredPackages, ['Riverpod', 'go_router']);
      expect(entity.configuredPackages.length, 2);
    });
  });
}
