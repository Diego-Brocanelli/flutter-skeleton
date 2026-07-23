import '../../domain/entities/home_entity.dart';

/// Representação bruta dos dados da Home, no formato que sai do
/// datasource (aqui, um Map local; numa feature remota, seria o JSON).
class HomeDto {
  const HomeDto({
    required this.welcomeMessage,
    required this.configuredPackages,
  });

  factory HomeDto.fromMap(Map<String, dynamic> map) {
    return HomeDto(
      welcomeMessage: map['welcomeMessage'] as String,
      configuredPackages: List<String>.from(map['configuredPackages'] as List),
    );
  }

  final String welcomeMessage;
  final List<String> configuredPackages;

  /// Converte o DTO (formato do datasource) para a entidade de domínio.
  HomeEntity toEntity() {
    return HomeEntity(
      welcomeMessage: welcomeMessage,
      configuredPackages: configuredPackages,
    );
  }
}
