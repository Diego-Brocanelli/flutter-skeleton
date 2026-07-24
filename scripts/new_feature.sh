#!/usr/bin/env bash
#
# Cria a estrutura básica de uma nova feature no Skeleton
# Uso: ./scripts/new_feature.sh "Nome da Feature"

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Uso: ./scripts/new_feature.sh \"Nome da Feature\""
  echo "Ex:  ./scripts/new_feature.sh auth"
  exit 1
fi

RAW_NAME="$1"
SLUG=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')
PASCAL=$(echo "$SLUG" | sed -E 's/(^|-)(.)/\U\2/g')

FEATURE_DIR="lib/src/features/$SLUG"

echo "🚀 Criando feature: $SLUG"

mkdir -p "$FEATURE_DIR"/data/{datasources,dtos,repositories}
mkdir -p "$FEATURE_DIR"/domain/{entities,repositories,usecases}
mkdir -p "$FEATURE_DIR"/presentation/{controllers,pages,widgets}

# Entity
cat > "$FEATURE_DIR/domain/entities/${SLUG}_entity.dart" << EOF
class ${PASCAL}Entity {
  const ${PASCAL}Entity({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
EOF

# Repository (abstração)
cat > "$FEATURE_DIR/domain/repositories/${SLUG}_repository.dart" << EOF
import '../entities/${SLUG}_entity.dart';

abstract class ${PASCAL}Repository {
  Future<${PASCAL}Entity> get${PASCAL}Data();
}
EOF

# Repository Implementation
cat > "$FEATURE_DIR/data/repositories/${SLUG}_repository_impl.dart" << EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../domain/repositories/${SLUG}_repository.dart';
import '../datasources/${SLUG}_remote_datasource.dart';

final ${SLUG}RepositoryProvider = Provider<${PASCAL}Repository>((ref) {
  return ${PASCAL}RepositoryImpl(const ${PASCAL}RemoteDataSource());
});

class ${PASCAL}RepositoryImpl implements ${PASCAL}Repository {
  const ${PASCAL}RepositoryImpl(this._dataSource);

  final ${PASCAL}RemoteDataSource _dataSource;

  @override
  Future<${PASCAL}Entity> get${PASCAL}Data() async {
    // TODO: Implementar chamada ao datasource
    final data = await _dataSource.fetch${PASCAL}Data();
    return ${PASCAL}Entity(id: data['id'] ?? '1', name: data['name'] ?? 'Default');
  }
}
EOF

# Remote DataSource
cat > "$FEATURE_DIR/data/datasources/${SLUG}_remote_datasource.dart" << EOF
class ${PASCAL}RemoteDataSource {
  const ${PASCAL}RemoteDataSource();

  Future<Map<String, dynamic>> fetch${PASCAL}Data() async {
    // TODO: Implementar chamada real à API (Dio, http, etc.)
    throw UnimplementedError('Implementar integração com API');
  }
}
EOF

# Notifier / Controller
cat > "$FEATURE_DIR/presentation/controllers/${SLUG}_notifier.dart" << EOF
import 'package:riverpod/riverpod.dart';

import '../../domain/entities/${SLUG}_entity.dart';
import '../../domain/repositories/${SLUG}_repository.dart';

final ${SLUG}NotifierProvider = AsyncNotifierProvider<${PASCAL}Notifier, ${PASCAL}Entity?>(
  ${PASCAL}Notifier.new,
);

class ${PASCAL}Notifier extends AsyncNotifier<${PASCAL}Entity?> {
  @override
  Future<${PASCAL}Entity?> build() => Future.value(null);

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(${SLUG}RepositoryProvider).get${PASCAL}Data(),
    );
  }
}
EOF

# Page
cat > "$FEATURE_DIR/presentation/pages/${SLUG}_page.dart" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/${SLUG}_notifier.dart';

class ${PASCAL}Page extends ConsumerWidget {
  const ${PASCAL}Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${SLUG}NotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('${RAW_NAME}')),
      body: state.when(
        data: (data) => const Center(child: Text('Feature pronta!')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: \$error')),
      ),
    );
  }
}
EOF

# Widget exemplo
cat > "$FEATURE_DIR/presentation/widgets/${SLUG}_header_widget.dart" << EOF
import 'package:flutter/material.dart';

class ${PASCAL}HeaderWidget extends StatelessWidget {
  const ${PASCAL}HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Cabeçalho da Feature',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
EOF

echo "✅ Feature '${SLUG}' criada com sucesso!"
echo "📍 Local: $FEATURE_DIR"
echo ""
echo "Próximos passos:"
echo "   1. Adicione a rota no app_router.dart"
echo "   2. Implemente a lógica no RemoteDataSource"
echo "   3. Chame .load() no Notifier quando necessário"
EOF
