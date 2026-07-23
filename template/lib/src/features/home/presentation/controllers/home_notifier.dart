import 'package:riverpod/riverpod.dart';

import '../../domain/entities/home_entity.dart';
import '../../domain/usecases/get_home_data_usecase.dart';

final homeNotifierProvider = AsyncNotifierProvider<HomeNotifier, HomeEntity>(
  HomeNotifier.new,
);

/// Controller (Notifier) da tela inicial.
///
/// Diferente do padrão gerado por `make new-feature` (que começa com
/// estado nulo e espera uma chamada explícita a `.load()`, pensado para
/// ações disparadas pelo usuário), a Home carrega os dados assim que a
/// tela é aberta — não faz sentido o usuário precisar "pedir" pra ver a
/// tela de boas-vindas.
class HomeNotifier extends AsyncNotifier<HomeEntity> {
  @override
  Future<HomeEntity> build() {
    return ref.read(getHomeDataUsecaseProvider).call();
  }
}
