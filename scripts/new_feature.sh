#!/usr/bin/env bash
#
# new_feature.sh
#
# Cria a estrutura de uma nova feature no Flutter Skeleton (lib + testes
# espelhados em test/), seguindo o padrão do template:
#
#   lib/src/features/<slug>/
#   ├── data/
#   │   ├── datasources/<slug>_remote_datasource.dart
#   │   └── repositories/<slug>_repository_impl.dart
#   ├── domain/
#   │   ├── entities/<slug>_entity.dart
#   │   └── repositories/<slug>_repository.dart
#   └── presentation/
#       ├── notifiers/<slug>_notifier.dart
#       ├── pages/<slug>_page.dart
#       └── widgets/<slug>_header_widget.dart
#
# Sem dtos/ (a conversão acontece direto no repository_impl) e sem
# usecases/ como pasta padrão (arquivo solto em domain/, só quando a
# lógica realmente pedir — veja docs/usecases-e-domain-services.md).
#
# Uso:
#   scripts/new_feature.sh "Nome da Feature"
#   scripts/new_feature.sh              # pergunta o nome interativamente

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
  # containers com locale POSIX/C, o transliterate falha silenciosamente
  # e perde parte do nome (ex.: "ção" vira lixo em vez de "cao").
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
#
# Importante: é essa variante (sem hífen) que deve ser usada em qualquer
# identificador Dart (nomes de provider, variáveis) — usar o SLUG
# diretamente quebra a compilação em features com nome composto, porque
# hífen não é caractere válido em identificador Dart.
to_camel_case() {
  local pascal="$1"
  printf '%s%s' "$(tr '[:upper:]' '[:lower:]' <<< "${pascal:0:1}")" "${pascal:1}"
}

# Escapa aspas simples para uso seguro dentro de strings Dart 'assim'.
dart_escape_single_quotes() {
  printf '%s' "$1" | sed "s/'/\\\\'/g"
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
DART_SAFE_NAME=$(dart_escape_single_quotes "$RAW_NAME")
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

yellow "🚀 Criando feature '${SLUG}' a partir de '${RAW_NAME}'..."

mkdir -p "${FEATURE_DIR}/data/datasources"
mkdir -p "${FEATURE_DIR}/data/repositories"
mkdir -p "${FEATURE_DIR}/domain/entities"
mkdir -p "${FEATURE_DIR}/domain/repositories"
mkdir -p "${FEATURE_DIR}/presentation/notifiers"
mkdir -p "${FEATURE_DIR}/presentation/pages"
mkdir -p "${FEATURE_DIR}/presentation/widgets"

# ---- domain/entities ---------------------------------------------------------

cat > "${FEATURE_DIR}/domain/entities/${SLUG}_entity.dart" <<EOF
/// Entidade de domínio de "${RAW_NAME}".
///
/// Objeto de negócio puro: sem anotação de serialização, sem depender de
/// nada de \`data/\` ou \`presentation/\`.
class ${PASCAL_NAME}Entity {
  const ${PASCAL_NAME}Entity({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
EOF

# ---- domain/repositories --------------------------------------------------------

cat > "${FEATURE_DIR}/domain/repositories/${SLUG}_repository.dart" <<EOF
import '../entities/${SLUG}_entity.dart';

/// Contrato que a camada de dados (\`data/repositories\`) precisa implementar.
///
/// O domínio depende apenas desta abstração — nunca da implementação
/// concreta (${PASCAL_NAME}RepositoryImpl).
abstract class ${PASCAL_NAME}Repository {
  Future<${PASCAL_NAME}Entity> get${PASCAL_NAME}Data();
}
EOF

# ---- data/datasources ------------------------------------------------------------

cat > "${FEATURE_DIR}/data/datasources/${SLUG}_remote_datasource.dart" <<EOF
/// Fonte de dados remota de "${RAW_NAME}".
///
/// Responsabilidade: falar com o mundo externo (API REST via Dio, etc.).
/// Não deve conter regra de negócio — só busca/envia dados brutos.
///
/// Se a feature não depender de API (ex.: dados só locais), troque por um
/// datasource local — o padrão se adapta à necessidade real da feature.
class ${PASCAL_NAME}RemoteDataSource {
  const ${PASCAL_NAME}RemoteDataSource();

  Future<Map<String, dynamic>> fetch${PASCAL_NAME}Data() async {
    // TODO: implementar a chamada real à API (Dio, http, etc.).
    throw UnimplementedError('Implementar integração com API');
  }
}
EOF

# ---- data/repositories --------------------------------------------------------

cat > "${FEATURE_DIR}/data/repositories/${SLUG}_repository_impl.dart" <<EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../domain/repositories/${SLUG}_repository.dart';
import '../datasources/${SLUG}_remote_datasource.dart';

final ${CAMEL_NAME}RepositoryProvider = Provider<${PASCAL_NAME}Repository>((ref) {
  return ${PASCAL_NAME}RepositoryImpl(const ${PASCAL_NAME}RemoteDataSource());
});

/// Implementação concreta de [${PASCAL_NAME}Repository].
///
/// Busca o dado bruto no datasource e já devolve a Entity pronta — a
/// conversão acontece aqui mesmo, sem precisar de uma classe de DTO
/// separada.
class ${PASCAL_NAME}RepositoryImpl implements ${PASCAL_NAME}Repository {
  const ${PASCAL_NAME}RepositoryImpl(this._dataSource);

  final ${PASCAL_NAME}RemoteDataSource _dataSource;

  @override
  Future<${PASCAL_NAME}Entity> get${PASCAL_NAME}Data() async {
    final data = await _dataSource.fetch${PASCAL_NAME}Data();
    return ${PASCAL_NAME}Entity(
      id: data['id'] as String? ?? '1',
      name: data['name'] as String? ?? 'Default',
    );
  }
}
EOF

# ---- presentation/notifiers ------------------------------------------------

cat > "${FEATURE_DIR}/presentation/notifiers/${SLUG}_notifier.dart" <<EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../data/repositories/${SLUG}_repository_impl.dart';

final ${CAMEL_NAME}NotifierProvider =
    AsyncNotifierProvider<${PASCAL_NAME}Notifier, ${PASCAL_NAME}Entity?>(
  ${PASCAL_NAME}Notifier.new,
);

/// Controller (Notifier) da tela de "${RAW_NAME}".
///
/// Começa com estado nulo e espera uma chamada explícita a \`.load()\` —
/// pensado para ações disparadas pelo usuário. Se a tela deve carregar
/// dados assim que abre (sem ação do usuário), prefira já retornar o
/// dado carregado direto no \`build()\` (veja a feature "home" como
/// referência desse padrão alternativo).
class ${PASCAL_NAME}Notifier extends AsyncNotifier<${PASCAL_NAME}Entity?> {
  @override
  Future<${PASCAL_NAME}Entity?> build() => Future.value(null);

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(${CAMEL_NAME}RepositoryProvider).get${PASCAL_NAME}Data(),
    );
  }
}
EOF

# ---- presentation/pages ----------------------------------------------------------

cat > "${FEATURE_DIR}/presentation/pages/${SLUG}_page.dart" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifiers/${SLUG}_notifier.dart';
import '../widgets/${SLUG}_header_widget.dart';

/// Tela principal da feature "${RAW_NAME}".
class ${PASCAL_NAME}Page extends ConsumerWidget {
  const ${PASCAL_NAME}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${CAMEL_NAME}NotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('${DART_SAFE_NAME}')),
      body: Column(
        children: [
          const ${PASCAL_NAME}HeaderWidget(),
          Expanded(
            child: state.when(
              data: (data) => Center(
                child: Text(data == null ? 'Nenhum dado carregado' : data.name),
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
        '${DART_SAFE_NAME}',
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
mkdir -p "${TEST_FEATURE_DIR}/data/repositories"
mkdir -p "${TEST_FEATURE_DIR}/domain/entities"
mkdir -p "${TEST_FEATURE_DIR}/domain/repositories"
mkdir -p "${TEST_FEATURE_DIR}/presentation/notifiers"
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
          .thenAnswer((_) async => {'id': '123', 'name': 'Exemplo'});

      final repository = ${PASCAL_NAME}RepositoryImpl(dataSource);
      final entity = await repository.get${PASCAL_NAME}Data();

      expect(entity.id, '123');
      expect(entity.name, 'Exemplo');
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
      const entity = ${PASCAL_NAME}Entity(id: '123', name: 'Exemplo');

      expect(entity.id, '123');
      expect(entity.name, 'Exemplo');
    });
  });
}
EOF

# ---- presentation/notifiers -----------------------------------------------------

cat > "${TEST_FEATURE_DIR}/presentation/notifiers/${SLUG}_notifier_test.dart" <<EOF
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${PACKAGE_NAME}/src/features/${SLUG}/data/repositories/${SLUG}_repository_impl.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/entities/${SLUG}_entity.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/domain/repositories/${SLUG}_repository.dart';
import 'package:${PACKAGE_NAME}/src/features/${SLUG}/presentation/notifiers/${SLUG}_notifier.dart';

class _Mock${PASCAL_NAME}Repository extends Mock implements ${PASCAL_NAME}Repository {}

void main() {
  group('${PASCAL_NAME}Notifier', () {
    test('load() atualiza o estado com o dado retornado pelo repository', () async {
      final repository = _Mock${PASCAL_NAME}Repository();
      const entity = ${PASCAL_NAME}Entity(id: '123', name: 'Exemplo');
      when(() => repository.get${PASCAL_NAME}Data()).thenAnswer((_) async => entity);

      final container = ProviderContainer(
        overrides: [
          ${CAMEL_NAME}RepositoryProvider.overrideWithValue(repository),
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

    expect(find.text('${DART_SAFE_NAME}'), findsWidgets);
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

    expect(find.text('${DART_SAFE_NAME}'), findsOneWidget);
  });
}
EOF

green "✅ Testes gerados com sucesso em ${TEST_FEATURE_DIR}/"
echo ""
echo "   ${FEATURE_DIR}/                        ${TEST_FEATURE_DIR}/"
echo "   ├── data/                              ├── data/"
echo "   │   ├── datasources/${SLUG}_remote_datasource.dart"
echo "   │   └── repositories/${SLUG}_repository_impl.dart"
echo "   ├── domain/                            ├── domain/"
echo "   │   ├── entities/${SLUG}_entity.dart"
echo "   │   └── repositories/${SLUG}_repository.dart   (sem teste — só interface)"
echo "   └── presentation/                      └── presentation/"
echo "       ├── notifiers/${SLUG}_notifier.dart"
echo "       ├── pages/${SLUG}_page.dart"
echo "       └── widgets/${SLUG}_header_widget.dart"
echo ""
echo "Próximos passos:"
echo "   1. Adicione a rota em app_router.dart"
echo "   2. Implemente a chamada real em ${SLUG}_remote_datasource.dart"
echo "   3. Chame .load() no notifier quando o usuário disparar a ação"
echo ""

if [[ "$PACKAGE_NAME" == "<seu_pacote>" ]]; then
  yellow "⚠️  Lembre-se de trocar '<seu_pacote>' pelo nome real do pacote"
  yellow "   (campo 'name:' do pubspec.yaml) nos imports dos arquivos de teste."
fi