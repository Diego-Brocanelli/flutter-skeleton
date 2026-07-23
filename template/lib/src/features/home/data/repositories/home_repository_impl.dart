import 'package:riverpod/riverpod.dart';

import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';
import '../dtos/home_dto.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(const HomeLocalDataSource());
});

/// Implementação concreta de [HomeRepository].
///
/// Orquestra a fonte de dados (datasource) e converte DTO -> Entity antes
/// de devolver para o domínio.
class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource);

  final HomeLocalDataSource _dataSource;

  @override
  Future<HomeEntity> getHomeData() async {
    final map = _dataSource.fetchHomeData();
    return HomeDto.fromMap(map).toEntity();
  }
}
