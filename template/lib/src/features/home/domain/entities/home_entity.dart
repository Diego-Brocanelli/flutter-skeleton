class HomeEntity {
  const HomeEntity({
    required this.welcomeMessage,
    required this.configuredPackages,
  });

  final String welcomeMessage;
  final List<String> configuredPackages;
}
