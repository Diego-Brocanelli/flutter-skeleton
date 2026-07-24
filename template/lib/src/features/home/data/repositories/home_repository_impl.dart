import 'package:riverpod/riverpod.dart';

import '../../domain/entities/home_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(const HomeLocalDataSource());
});

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._dataSource);

  final HomeLocalDataSource _dataSource;

  @override
  Future<HomeEntity> getHomeData() async {
    final map = _dataSource.fetchHomeData();
    return HomeEntity(
      welcomeMessage: map['welcomeMessage'] as String,
      configuredPackages: List<String>.from(map['configuredPackages']),
    );
  }
}
