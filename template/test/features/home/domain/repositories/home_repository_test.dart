import 'package:flutter_test/flutter_test.dart';
import 'package:__PACKAGE_NAME__/src/features/home/domain/repositories/home_repository.dart';

void main() {
  test('HomeRepository deve ter o método getHomeData', () {
    // Teste de contrato (contrato da interface)
    expect(HomeRepository, isAbstract);
  });
}
