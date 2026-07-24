class HomeLocalDataSource {
  const HomeLocalDataSource();

  Map<String, dynamic> fetchHomeData() {
    return {
      'welcomeMessage': 'Bem-vindo ao Flutter Skeleton!',
      'configuredPackages': ['Riverpod', 'go_router', 'Freezed'],
    };
  }
}
