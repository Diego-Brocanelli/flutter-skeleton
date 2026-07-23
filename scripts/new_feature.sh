#!/usr/bin/env bash
#
# Cria a estrutura Clean Architecture completa de uma nova feature
# dentro de lib/src/features/<dominio>, junto com o espelho de testes em
# test/features/<feature> — incluindo TODAS as subpastas (data/domain/
# presentation com suas respectivas camadas), sempre, sem versão "enxuta".
#
# Isso é proposital: a ideia é que toda feature, da primeira à centésima,
# siga exatamente a mesma base. Um dev sênior desenha o padrão uma vez
# (aqui), e qualquer dev júnior que rodar `make new-feature` reproduz esse
# mesmo padrão sem precisar decidir nada.
#
#   lib/src/features/<dominio>/
#   ├── data/
#   │   ├── datasources/<dominio>_remote_datasource.dart
#   │   ├── dtos/<dominio>_dto.dart
#   │   └── repositories/<dominio>_repository_impl.dart
#   ├── domain/
#   │   ├── entities/<dominio>_entity.dart
#   │   ├── repositories/<dominio>_repository.dart
#   │   └── usecases/get_<dominio>_data_usecase.dart
#   └── presentation/
#       ├── controllers/<dominio>_notifier.dart
#       ├── pages/<dominio>_page.dart
#       └── widgets/<dominio>_header_widget.dart
#
#   test/features/<feature>/  (mesmo espelho, exceto domain/repositories/
#   — é só uma interface, sem lógica própria para testar)
#
# Uso:
#   scripts/new_feature.sh "Nome da Feature"
#
# Se nenhum argumento for passado, o script pergunta interativamente.

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

FEATURES_DIR="lib/src/features"
TEST_FEATURES_DIR="test/features"

# ---------------------------------------------------------------------------
# Helpers de output
# ---------------------------------------------------------------------------

red() { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
# Helpers de nomenclatura
# ---------------------------------------------------------------------------

# Converte texto livre em slug kebab-case, sem acentos/caracteres especiais.
# Ex.: "Exportação de Produtos" -> "exportacao-de-produtos"
slugify() {
  local input="$1"
  local output

  output=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')

  # Remove acentos via iconv, forçando um locale UTF-8. Sem isso, em
  # containers com locale POSIX/C, o transliterate falha silenciosamente.
  if command -v iconv >/dev/null 2>&1; then
    output=$(LC_ALL=C.utf8 iconv -f UTF-8 -t ASCII//TRANSLIT <<< "$output" 2>/dev/null \
      || printf '%s' "$output")
  fi

  output=$(printf '%s' "$output" | sed -E 's/[^a-z0-9]+/-/g')
  output=$(printf '%s' "$output" | sed -E 's/-+/-/g; s/^-+//; s/-+$//')

  printf '%s' "$output"
}

# Converte um slug kebab-case em PascalCase.
# Ex.: "exportacao-de-produtos" -> "ExportacaoDeProdutos"
to_pascal_case() {
  local slug="$1"
  local pascal=""
  local part

  IFS='-' read -ra parts <<< "$slug"
  for part in "${parts[@]}"; do
    pascal+="$(tr '[:lower:]' '[:upper:]' <<< "${part:0:1}")${part:1}"
  done

  printf '%s' "$pascal"
}

# Converte PascalCase em camelCase (primeira letra minúscula).
# Ex.: "ExportacaoDeProdutos" -> "exportacaoDeProdutos"
to_camel_case() {
  local pascal="$1"
  printf '%s%s' "$(tr '[:upper:]' '[:lower:]' <<< "${pascal:0:1}")" "${pascal:1}"
}

# Lê o campo "name:" do pubspec.yaml na raiz do projeto, se existir.
# Usado para montar os imports "package:<nome>/..." nos testes gerados.
detect_package_name() {
  if [[ -f "pubspec.yaml" ]]; then
    grep -E '^name:' pubspec.yaml | head -n1 | sed -E 's/^name:[[:space:]]*//' | tr -d '"'"'"' \r'
  fi
}

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

RAW_NAME="${1:-}"

if [[ -z "$RAW_NAME" ]]; then
  read -rp "Nome da feature: " RAW_NAME
fi

if [[ -z "$RAW_NAME" ]]; then
  red "❌ Nome da feature não pode ser vazio."
  exit 1
fi

SLUG=$(slugify "$RAW_NAME")

if [[ -z "$SLUG" ]]; then
  red "❌ Não foi possível gerar um nome válido a partir de '$RAW_NAME'."
  exit 1
fi

PASCAL_NAME=$(to_pascal_case "$SLUG")
CAMEL_NAME=$(to_camel_case "$PASCAL_NAME")
FEATURE_DIR="${FEATURES_DIR}/${SLUG}"
TEST_FEATURE_DIR="${TEST_FEATURES_DIR}/${SLUG}"
PACKAGE_NAME=$(detect_package_name)
PACKAGE_NAME="${PACKAGE_NAME:-<seu_pacote>}"

# ---------------------------------------------------------------------------
# Validação
# ---------------------------------------------------------------------------

if [[ -d "$FEATURE_DIR" ]]; then
  red "❌ A feature '${SLUG}' já existe em ${FEATURE_DIR}"
  exit 1
fi

if [[ -d "$TEST_FEATURE_DIR" ]]; then
  red "❌ Já existem testes para a feature '${SLUG}' em ${TEST_FEATURE_DIR}"
  exit 1
fi

if [[ "$PACKAGE_NAME" == "<seu_pacote>" ]]; then
  yellow "⚠️  Não encontrei 'name:' em pubspec.yaml para detectar o nome do"
  yellow "   pacote. Os imports 'package:...' gerados nos testes vão usar"
  yellow "   '<seu_pacote>' como placeholder — troque manualmente depois."
fi

# ---------------------------------------------------------------------------
# Geração da estrutura lib/
# ---------------------------------------------------------------------------

yellow "Criando feature '${SLUG}' a partir de '${RAW_NAME}'..."

mkdir -p "${FEATURE_DIR}/data/datasources"
mkdir -p "${FEATURE_DIR}/data/dtos"
mkdir -p "${FEATURE_DIR}/data/repositories"
mkdir -p "${FEATURE_DIR}/domain/entities"
mkdir -p "${FEATURE_DIR}/domain/repositories"
mkdir -p "${FEATURE_DIR}/domain/usecases"
mkdir -p "${FEATURE_DIR}/presentation/controllers"
mkdir -p "${FEATURE_DIR}/presentation/pages"
mkdir -p "${FEATURE_DIR}/presentation/widgets"

# ---- data/datasources -------------------------------------------------------

cat > "${FEATURE_DIR}/data/datasources/${SLUG}_remote_datasource.dart" <<EOF
/// Fonte de dados remota da feature "${RAW_NAME}".
///
/// Responsabilidade: falar com o mundo externo (API REST via Dio, etc.).
/// Não deve conter regra de negócio — só busca/envia dados brutos.
class ${PASCAL_NAME}RemoteDataSource {
  const ${PASCAL_NAME}RemoteDataSource();

  // TODO: injete aqui o cliente HTTP (ex.: Dio) via construtor.

  Future<Map<String, dynamic>> fetch${PASCAL_NAME}Data() async {
    // TODO: implementar a chamada real à API.
    throw UnimplementedError();
  }
}
EOF

# ---- data/dtos ---------------------------------------------------------------

cat > "${FEATURE_DIR}/data/dtos/${SLUG}_dto.dart" <<EOF
import '../../domain/entities/${SLUG}_entity.dart';

/// Representação bruta dos dados de "${RAW_NAME}" vindos da API (JSON).
///
/// Fica isolado de propósito: mudanças no formato da API não devem vazar
/// para \`domain/entities\`.
class ${PASCAL_NAME}Dto {
  const ${PASCAL_NAME}Dto({required this.id});

  factory ${PASCAL_NAME}Dto.fromJson(Map<String, dynamic> json) {
    return ${PASCAL_NAME}Dto(id: json['id'] as String);
  }

  final String id;

  /// Converte o DTO (formato de API) para a entidade de domínio.
  ${PASCAL_NAME}Entity toEntity() {
    return ${PASCAL_NAME}Entity(id: id);
  }
}
EOF

# ---- data/repositories --------------------------------------------------------

cat > "${FEATURE_DIR}/data/repositories/${SLUG}_repository_impl.dart" <<EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../domain/repositories/${SLUG}_repository.dart';
import '../datasources/${SLUG}_remote_datasource.dart';
import '../dtos/${SLUG}_dto.dart';

final ${CAMEL_NAME}RepositoryProvider = Provider<${PASCAL_NAME}Repository>((ref) {
  return ${PASCAL_NAME}RepositoryImpl(const ${PASCAL_NAME}RemoteDataSource());
});

/// Implementação concreta de [${PASCAL_NAME}Repository].
///
/// Orquestra a fonte de dados (datasource) e converte DTO -> Entity antes
/// de devolver para o domínio.
class ${PASCAL_NAME}RepositoryImpl implements ${PASCAL_NAME}Repository {
  const ${PASCAL_NAME}RepositoryImpl(this._dataSource);

  final ${PASCAL_NAME}RemoteDataSource _dataSource;

  @override
  Future<${PASCAL_NAME}Entity> get${PASCAL_NAME}Data() async {
    final json = await _dataSource.fetch${PASCAL_NAME}Data();
    return ${PASCAL_NAME}Dto.fromJson(json).toEntity();
  }
}
EOF

# ---- domain/entities -----------------------------------------------------------

cat > "${FEATURE_DIR}/domain/entities/${SLUG}_entity.dart" <<EOF
/// Entidade de domínio de "${RAW_NAME}".
///
/// Objeto de negócio puro: sem anotação de serialização, sem depender de
/// nada de \`data/\` ou \`presentation/\`.
class ${PASCAL_NAME}Entity {
  const ${PASCAL_NAME}Entity({required this.id});

  final String id;
}
EOF

# ---- domain/repositories --------------------------------------------------------

cat > "${FEATURE_DIR}/domain/repositories/${SLUG}_repository.dart" <<EOF
import '../entities/${SLUG}_entity.dart';

/// Contrato que a camada de dados (\`data/repositories\`) precisa implementar.
///
/// O domínio depende apenas desta abstração — nunca da implementação
/// concreta (${PASCAL_NAME}RepositoryImpl). Isso permite trocar a fonte de
/// dados (ex.: API -> cache local) sem tocar em \`domain/\` nem
/// \`presentation/\`.
abstract class ${PASCAL_NAME}Repository {
  Future<${PASCAL_NAME}Entity> get${PASCAL_NAME}Data();
}
EOF

# ---- domain/usecases ------------------------------------------------------------

cat > "${FEATURE_DIR}/domain/usecases/get_${SLUG}_data_usecase.dart" <<EOF
import 'package:riverpod/riverpod.dart';

import '../../data/repositories/${SLUG}_repository_impl.dart';
import '../entities/${SLUG}_entity.dart';
import '../repositories/${SLUG}_repository.dart';

final get${PASCAL_NAME}DataUsecaseProvider =
    Provider<Get${PASCAL_NAME}DataUsecase>((ref) {
  return Get${PASCAL_NAME}DataUsecase(ref.read(${CAMEL_NAME}RepositoryProvider));
});

/// Caso de uso: obter os dados de "${RAW_NAME}".
///
/// Uma ação de negócio por classe. Hoje é só um repasse ao repository, mas
/// é aqui que entra qualquer regra adicional (validação, combinação de
/// múltiplas fontes, etc.) sem misturar com a camada de apresentação.
class Get${PASCAL_NAME}DataUsecase {
  const Get${PASCAL_NAME}DataUsecase(this._repository);

  final ${PASCAL_NAME}Repository _repository;

  Future<${PASCAL_NAME}Entity> call() {
    return _repository.get${PASCAL_NAME}Data();
  }
}
EOF

# ---- presentation/controllers ------------------------------------------------

cat > "${FEATURE_DIR}/presentation/controllers/${SLUG}_notifier.dart" <<EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../domain/usecases/get_${SLUG}_data_usecase.dart';

final ${CAMEL_NAME}NotifierProvider =
    AsyncNotifierProvider<${PASCAL_NAME}Notifier, ${PASCAL_NAME}Entity?>(
  ${PASCAL_NAME}Notifier.new,
);

/// Controller (Notifier) da tela de "${RAW_NAME}".
///
/// Orquestra usecases e expõe o estado para a UI. Não deve conter lógica
/// de negócio (isso é papel do usecase) nem detalhe de widget.
class ${PASCAL_NAME}Notifier extends AsyncNotifier<${PASCAL_NAME}Entity?> {
  @override
  Future<${PASCAL_NAME}Entity?> build() async => null;

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(get${PASCAL_NAME}DataUsecaseProvider).call(),
    );
  }
}
EOF

# ---- presentation/pages ----------------------------------------------------------

cat > "${FEATURE_DIR}/presentation/pages/${SLUG}_page.dart" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/${SLUG}_notifier.dart';
import '../widgets/${SLUG}_header_widget.dart';

/// Tela principal da feature "${RAW_NAME}".
class ${PASCAL_NAME}Page extends ConsumerWidget {
  const ${PASCAL_NAME}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${CAMEL_NAME}NotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('${RAW_NAME}')),
      body: Column(
        children: [
          const ${PASCAL_NAME}HeaderWidget(),
          Expanded(
            child: state.when(
              data: (data) => Center(
                child: Text(data == null ? 'Nenhum dado carregado' : data.id),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Erro: \$error')),
            ),
          ),
        ],
      ),
    );
  }
}
EOF

# ---- presentation/widgets --------------------------------------------------------

cat > "${FEATURE_DIR}/presentation/widgets/${SLUG}_header_widget.dart" <<EOF
import 'package:flutter/material.dart';

/// Cabeçalho da tela de "${RAW_NAME}".
///
/// Extraído da página principal para manter \`${SLUG}_page.dart\` enxuta e
/// este widget testável isoladamente.
class ${PASCAL_NAME}HeaderWidget extends StatelessWidget {
  const ${PASCAL_NAME}HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        '${RAW_NAME}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
EOF

green "✅ Feature '${SLUG}' criada com sucesso em ${FEATURE_DIR}/"

# ---------------------------------------------------------------------------
# Geração da estrutura test/ (mesmo espelho)
# ---------------------------------------------------------------------------

mkdir -p "${TEST_FEATURE_DIR}/data/datasources"
mkdir -p "${TEST_FEATURE_DIR}/data/dtos"
mkdir -p "${TEST_FEATURE_DIR}/data/repositories"
mkdir -p "${TEST_FEATURE_DIR}/domain/entities"
mkdir -p "${TEST_FEATURE_DIR}/domain/repositories"
mkdir -p "${TEST_FEATURE_DIR}/domain/usecases"
mkdir -p "${TEST_FEATURE_DIR}/presentation/controllers"
mkdir -p "${TEST_FEATURE_DIR}/presentation/pages"
mkdir -p "${TEST_FEATURE_DIR}/presentation/widgets"

# domain/repositories é só uma interface (sem lógica própria) — não gera
# teste em cima dela, mas mantém a pasta rastreável no git com uma nota.
cat > "${TEST_FEATURE_DIR}/domain/repositories/.gitkeep" <<EOF
# Pasta mantida vazia de propósito: ${PASCAL_NAME}Repository (em
# lib/.../domain/repositories/) é só uma interface/contrato, sem lógica
# própria. Não há o que testar aqui — quem testa o comportamento é
# ${PASCAL_NAME}RepositoryImpl, em data/repositories/.
EOF

# ---- data/datasources ------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/data/datasources/${SLUG}_remote_datasource_test.dart" <<EOF
import 'package:flutter_test/flutter_test.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/data/datasources/${SLUG}_remote_datasource.dart';

void main() {
  group('${PASCAL_NAME}RemoteDataSource', () {
    test('TODO: substituir por um teste real assim que a chamada de API existir', () {
      const dataSource = ${PASCAL_NAME}RemoteDataSource();

      expect(
        () => dataSource.fetch${PASCAL_NAME}Data(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
EOF

# ---- data/dtos --------------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/data/dtos/${SLUG}_dto_test.dart" <<EOF
import 'package:flutter_test/flutter_test.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/data/dtos/${SLUG}_dto.dart';

void main() {
  group('${PASCAL_NAME}Dto', () {
    test('fromJson faz o parse corretamente', () {
      final dto = ${PASCAL_NAME}Dto.fromJson({'id': '123'});

      expect(dto.id, '123');
    });

    test('toEntity converte para a entidade de domínio', () {
      const dto = ${PASCAL_NAME}Dto(id: '123');

      final entity = dto.toEntity();

      expect(entity.id, '123');
    });
  });
}
EOF

# ---- data/repositories --------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/data/repositories/${SLUG}_repository_impl_test.dart" <<EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/data/datasources/${SLUG}_remote_datasource.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/data/repositories/${SLUG}_repository_impl.dart';

class _Mock${PASCAL_NAME}RemoteDataSource extends Mock
    implements ${PASCAL_NAME}RemoteDataSource {}

void main() {
  group('${PASCAL_NAME}RepositoryImpl', () {
    test('get${PASCAL_NAME}Data converte o retorno do datasource em entidade', () async {
      final dataSource = _Mock${PASCAL_NAME}RemoteDataSource();
      when(() => dataSource.fetch${PASCAL_NAME}Data())
          .thenAnswer((_) async => {'id': '123'});

      final repository = ${PASCAL_NAME}RepositoryImpl(dataSource);
      final entity = await repository.get${PASCAL_NAME}Data();

      expect(entity.id, '123');
    });
  });
}
EOF

# ---- domain/entities ----------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/domain/entities/${SLUG}_entity_test.dart" <<EOF
import 'package:flutter_test/flutter_test.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/entities/${SLUG}_entity.dart';

void main() {
  group('${PASCAL_NAME}Entity', () {
    test('armazena os campos recebidos no construtor', () {
      const entity = ${PASCAL_NAME}Entity(id: '123');

      expect(entity.id, '123');
    });
  });
}
EOF

# ---- domain/usecases -----------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/domain/usecases/get_${SLUG}_data_usecase_test.dart" <<EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/entities/${SLUG}_entity.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/repositories/${SLUG}_repository.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/usecases/get_${SLUG}_data_usecase.dart';

class _Mock${PASCAL_NAME}Repository extends Mock implements ${PASCAL_NAME}Repository {}

void main() {
  group('Get${PASCAL_NAME}DataUsecase', () {
    test('delega a chamada para o repository', () async {
      final repository = _Mock${PASCAL_NAME}Repository();
      const entity = ${PASCAL_NAME}Entity(id: '123');
      when(() => repository.get${PASCAL_NAME}Data()).thenAnswer((_) async => entity);

      final usecase = Get${PASCAL_NAME}DataUsecase(repository);
      final result = await usecase();

      expect(result, entity);
      verify(() => repository.get${PASCAL_NAME}Data()).called(1);
    });
  });
}
EOF

# ---- presentation/controllers -----------------------------------------------------

cat > "${TEST_FEATURE_DIR}/presentation/controllers/${SLUG}_notifier_test.dart" <<EOF
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/entities/${SLUG}_entity.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/usecases/get_${SLUG}_data_usecase.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/presentation/controllers/${SLUG}_notifier.dart';

class _MockGet${PASCAL_NAME}DataUsecase extends Mock
    implements Get${PASCAL_NAME}DataUsecase {}

void main() {
  group('${PASCAL_NAME}Notifier', () {
    test('load() atualiza o estado com o dado retornado pelo usecase', () async {
      final usecase = _MockGet${PASCAL_NAME}DataUsecase();
      const entity = ${PASCAL_NAME}Entity(id: '123');
      when(() => usecase()).thenAnswer((_) async => entity);

      final container = ProviderContainer(
        overrides: [
          get${PASCAL_NAME}DataUsecaseProvider.overrideWithValue(usecase),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(${CAMEL_NAME}NotifierProvider.notifier);
      await notifier.load();

      final state = container.read(${CAMEL_NAME}NotifierProvider);
      expect(state.value, entity);
    });
  });
}
EOF

# ---- presentation/pages -------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/presentation/pages/${SLUG}_page_test.dart" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/presentation/pages/${SLUG}_page.dart';

void main() {
  testWidgets('${PASCAL_NAME}Page exibe o título e o cabeçalho', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ${PASCAL_NAME}Page()),
      ),
    );

    expect(find.text('${RAW_NAME}'), findsWidgets);
  });
}
EOF

# ---- presentation/widgets ------------------------------------------------------------

cat > "${TEST_FEATURE_DIR}/presentation/widgets/${SLUG}_header_widget_test.dart" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/presentation/widgets/${SLUG}_header_widget.dart';

void main() {
  testWidgets('${PASCAL_NAME}HeaderWidget exibe o nome da feature', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ${PASCAL_NAME}HeaderWidget()),
    );

    expect(find.text('${RAW_NAME}'), findsOneWidget);
  });
}
EOF

green "✅ Testes gerados com sucesso em ${TEST_FEATURE_DIR}/"
echo ""
echo "   ${FEATURE_DIR}/                              ${TEST_FEATURE_DIR}/"
echo "   ├── data/                                   ├── data/"
echo "   │   ├── datasources/${SLUG}_remote_datasource.dart"
echo "   │   ├── dtos/${SLUG}_dto.dart"
echo "   │   └── repositories/${SLUG}_repository_impl.dart"
echo "   ├── domain/                                 ├── domain/"
echo "   │   ├── entities/${SLUG}_entity.dart"
echo "   │   ├── repositories/${SLUG}_repository.dart   (sem teste — só interface)"
echo "   │   └── usecases/get_${SLUG}_data_usecase.dart"
echo "   └── presentation/                           └── presentation/"
echo "       ├── controllers/${SLUG}_notifier.dart"
echo "       ├── pages/${SLUG}_page.dart"
echo "       └── widgets/${SLUG}_header_widget.dart"
echo ""

if [[ "$PACKAGE_NAME" == "<seu_pacote>" ]]; then
  yellow "⚠️  Lembre-se de trocar '<seu_pacote>' pelo nome real do pacote"
  yellow "   (campo 'name:' do pubspec.yaml) nos imports dos arquivos de teste."
fi