import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:__PACKAGE_NAME__/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:__PACKAGE_NAME__/src/features/home/domain/entities/home_entity.dart';
import 'package:__PACKAGE_NAME__/src/features/home/domain/repositories/home_repository.dart';
import 'package:__PACKAGE_NAME__/src/features/home/presentation/notifiers/home_notifier.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late MockHomeRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockHomeRepository();
    container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('homeNotifierProvider deve carregar dados ao build', () async {
    when(() => mockRepository.getHomeData()).thenAnswer(
      (_) async => const HomeEntity(
        welcomeMessage: 'Teste Notifier',
        configuredPackages: ['Riverpod'],
      ),
    );

    final notifier = container.read(homeNotifierProvider.future);

    final result = await notifier;

    expect(result.welcomeMessage, 'Teste Notifier');
    verify(() => mockRepository.getHomeData()).called(1);
  });
}
