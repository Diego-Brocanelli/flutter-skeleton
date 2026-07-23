/// Fonte de dados LOCAL da tela inicial.
///
/// Diferente da maioria das features (que normalmente têm um
/// RemoteDataSource falando com uma API), a Home não depende de nada
/// externo — por isso usa uma fonte de dados local. O `make new-feature`
/// assume uma API remota por padrão (o caso mais comum), mas nada impede
/// de trocar por uma fonte local, como aqui, quando fizer sentido para a
/// feature.
class HomeLocalDataSource {
  const HomeLocalDataSource();

  Map<String, dynamic> fetchHomeData() {
    return {
      'welcomeMessage': 'Bem-vindo ao Template!',
      'configuredPackages': ['Riverpod', 'go_router', 'Freezed'],
    };
  }
}
