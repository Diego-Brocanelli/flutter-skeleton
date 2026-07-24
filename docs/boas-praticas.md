# Boas Práticas

## Effective Dart

Este template segue as diretrizes oficiais do **[Effective Dart](https://dart.dev/effective-dart)** para manter o código consistente, legível e fácil de manter. Os pontos abaixo são os que mais aparecem no dia a dia — a referência completa vale a leitura, principalmente pra quem está começando com Dart.

### 1. Formatação e estilo

- Sempre rode `dart format .` (ou `make format`) antes de commitar.
- Linhas com **até 80 caracteres**, sempre que possível.
- Use `{}` em **todos** os blocos de fluxo, mesmo os de uma linha só.

```dart
// Bom
if (condition) {
  doSomething();
}

// Evite
if (condition) doSomething();
```

### 2. Convenções de nomenclatura

```dart
// Tipos: UpperCamelCase
class UserProfile {}
enum UserRole {}
extension StringExtensions on String {}

// Arquivos e pastas: snake_case
// user_repository.dart, home_notifier.dart, lib/src/features/home/

// Variáveis, funções e parâmetros: lowerCamelCase
final userName = 'João';
void fetchUserData(String userId) { ... }

// Constantes: lowerCamelCase
const defaultTimeout = Duration(seconds: 30);
const maxRetryCount = 3;
```

**Evite:**
```dart
const MAX_RETRY_COUNT = 3;   // SCREAMING_CAPS — não é convenção Dart
var mUser;                   // notação húngara
```

### 3. Imports e ordenação

```dart
// 1. dart:
import 'dart:async';
import 'dart:convert';

// 2. package:
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. imports relativos
import '../domain/entities/home_entity.dart';

// 4. exports, em seção separada
export 'src/models/user.dart';
```

### 4. Estrutura de projeto

A organização de pastas (Feature + DDD) tem um documento próprio: veja [Estrutura do Projeto](estrutura-do-projeto.md).

### 5. Documentação de código

Documente classes e métodos públicos com `///`, principalmente quando o comportamento não for óbvio pelo nome:

```dart
/// Recupera o perfil do usuário.
///
/// Retorna `null` se o usuário não existir.
///
/// ```dart
/// final user = await userService.getProfile('123');
/// ```
User? getProfile(String userId) { ... }
```

### 6. Boas práticas de código

```dart
// Prefira const sempre que possível
const button = ElevatedButton(
  onPressed: null,
  child: Text('Salvar'),
);

// Null safety: seja explícito
final name = user?.name ?? 'Anônimo';
final email = user!.email; // só use ! quando tiver certeza absoluta

// Funções e classes pequenas, com responsabilidade única
class UserRepository {
  Future<User> getUser(String id) async { ... }
}

// Use final por padrão; var só quando o valor precisa mudar
final theme = Theme.of(context);
```

### 7. Performance no Flutter

```dart
class UserCard extends StatelessWidget {
  const UserCard({required this.user, super.key}); // const constructor

  final User user;

  @override
  Widget build(BuildContext context) { ... }
}
```

Use `const` em widgets sempre que possível, e mantenha o `Notifier` só com estado e orquestração — nenhuma lógica de negócio deveria morar lá (isso é papel do `domain`; veja [Estrutura do Projeto](estrutura-do-projeto.md)).

## Recomendações finais

- Rode sempre o linter (`make analyze`) antes de abrir um PR.
- Escreva testes — o template já vem com a estrutura de testes espelhada, sem desculpa pra pular esse passo.
- Mantenha widgets pequenos e reutilizáveis, extraídos para `presentation/widgets/`.
- Riverpod é a solução de gerenciamento de estado deste template — mantenha consistência, não misture com outra abordagem no meio do caminho.

**Referência principal**: [Effective Dart](https://dart.dev/effective-dart)

## O que é o `analysis_options.yaml`?

É o arquivo de configuração do analisador estático do Dart (`dart analyze`). Nele você define:

- Quais regras do linter ficam ativas ou desativadas.
- Quais problemas viram erro, warning ou só um aviso informativo.
- Regras específicas do seu time ou projeto.

Ele fica na raiz do projeto, no mesmo nível do `pubspec.yaml`, e é essencial pra manter o código seguindo as convenções acima **de forma automática**, sem depender de review manual pra pegar cada detalhe.

**Como usar:**

```bash
make shell
dart analyze
```

Ou configure seu editor (VS Code / Android Studio / IntelliJ) para rodar a análise automaticamente ao salvar.