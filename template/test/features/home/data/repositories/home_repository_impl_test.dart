import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__PACKAGE_NAME__/src/features/home/data/datasources/home_local_datasource.dart';
import 'package:__PACKAGE_NAME__/src/features/home/data/repositories/home_repository_impl.dart';

class MockHomeLocalDataSource extends Mock implements HomeLocalDataSource {}

void main() {
  late MockHomeLocalDataSource mockDataSource;
  late HomeRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockHomeLocalDataSource();
    repository = HomeRepositoryImpl(mockDataSource);
  });

  test('deve buscar dados e retornar HomeEntity', () async {
    when(() => mockDataSource.fetchHomeData()).thenReturn({
      'welcomeMessage': 'Bem-vindo ao teste!',
      'configuredPackages': ['Riverpod', 'go_router'],
    });

    final result = await repository.getHomeData();

    expect(result.welcomeMessage, 'Bem-vindo ao teste!');
    expect(result.configuredPackages.length, 2);
  });
}
