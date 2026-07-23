import '../entities/home_entity.dart';

/// Contrato que a camada de dados (`data/repositories`) precisa implementar.
///
/// O domínio depende apenas desta abstração — nunca da implementação
/// concreta (HomeRepositoryImpl).
abstract class HomeRepository {
  Future<HomeEntity> getHomeData();
}
