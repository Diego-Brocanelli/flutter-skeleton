/// Entidade de domínio da tela inicial.
///
/// Objeto de negócio puro: sem anotação de serialização, sem depender de
/// nada de `data/` ou `presentation/`.
class HomeEntity {
  const HomeEntity({
    required this.welcomeMessage,
    required this.configuredPackages,
  });

  final String welcomeMessage;
  final List<String> configuredPackages;
}
