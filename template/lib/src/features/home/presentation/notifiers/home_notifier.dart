import 'package:riverpod/riverpod.dart';

import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_entity.dart';

final homeNotifierProvider = AsyncNotifierProvider<HomeNotifier, HomeEntity>(
  HomeNotifier.new,
);

class HomeNotifier extends AsyncNotifier<HomeEntity> {
  @override
  Future<HomeEntity> build() async {
    final repository = ref.read(homeRepositoryProvider);
    return repository.getHomeData();
  }
}
