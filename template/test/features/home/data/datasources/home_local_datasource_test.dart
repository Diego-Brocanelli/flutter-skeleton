import 'package:flutter_test/flutter_test.dart';
import 'package:__PACKAGE_NAME__/src/features/home/data/datasources/home_local_datasource.dart';

void main() {
  late HomeLocalDataSource dataSource;

  setUp(() {
    dataSource = const HomeLocalDataSource();
  });

  group('HomeLocalDataSource', () {
    test('deve retornar dados da tela inicial', () {
      final result = dataSource.fetchHomeData();

      expect(result['welcomeMessage'], isNotEmpty);
      expect(result['configuredPackages'], isA<List<String>>());
    });
  });
}
