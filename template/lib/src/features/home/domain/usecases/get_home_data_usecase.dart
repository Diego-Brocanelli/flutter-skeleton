import 'package:riverpod/riverpod.dart';

import '../../data/repositories/home_repository_impl.dart';
import '../entities/home_entity.dart';
import '../repositories/home_repository.dart';

final getHomeDataUsecaseProvider = Provider<GetHomeDataUsecase>((ref) {
  return GetHomeDataUsecase(ref.read(homeRepositoryProvider));
});

/// Caso de uso: obter os dados da tela inicial.
class GetHomeDataUsecase {
  const GetHomeDataUsecase(this._repository);

  final HomeRepository _repository;

  Future<HomeEntity> call() {
    return _repository.getHomeData();
  }
}
