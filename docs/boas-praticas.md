# Boas Práticas

## Boas Práticas da Comunidade Dart (Effective Dart)

Adote as diretrizes oficiais do **[Effective Dart](https://dart.dev/effective-dart)** para manter o código consistente, legível e fácil de manter.

### 1. Formatação e Estilo
- Sempre execute `dart format .`
- Linhas preferencialmente **≤ 80 caracteres**
- Use `{}` em **todos** os blocos de fluxo

```dart
// Bom
if (condition) {
  doSomething();
}

// Ruim
if (condition) doSomething();
```

### 2. Convenções de Nomenclatura

```dart
// Tipos
class UserProfile {}          // UpperCamelCase
enum UserRole {}              // UpperCamelCase
extension StringExtensions on String {} // UpperCamelCase

// Arquivos e pastas
// meu_app.dart, user_repository.dart, lib/src/

// Variáveis, funções e parâmetros
final userName = 'João';
void fetchUserData(String userId) { ... } // lowerCamelCase

// Constantes (prefer lowerCamelCase)
const defaultTimeout = Duration(seconds: 30);
const maxRetryCount = 3;
```

**Evite:**
```dart
const MAX_RETRY_COUNT = 3;        // SCREAMING_CAPS (evite em novo código)
var mUser;                        // notação húngara
```

### 3. Imports e Ordenação

```dart
// dart: primeiro
import 'dart:async';
import 'dart:convert';

// depois package:
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// depois imports relativos
import 'src/repositories/user_repository.dart';

// exports em seção separada
export 'src/models/user.dart';
```

### 4. Estrutura de Projeto

Veja o detalhe completo em [Estrutura do Projeto](estrutura-do-projeto.md).

### 5. Documentação

```dart
/// Recupera o perfil do usuário.
///
/// Se o usuário não existir, retorna `null`.
/// 
/// ```dart
/// final user = await userService.getProfile('123');
/// ```
User? getProfile(String userId) { ... }
```

### 6. Boas Práticas de Código (Flutter/Dart)

```dart
// Prefira const
const button = ElevatedButton(
  onPressed: null,
  child: Text('Salvar'),
);

// Null safety
final name = user?.name ?? 'Anônimo';
final email = user!.email; // só use ! quando tiver certeza

// Evite funções grandes
// Bom:
class UserRepository {
  Future<User> getUser(String id) async { ... }
}

// Use final quando possível
final theme = Theme.of(context);
```

### 7. Performance & Boas Práticas Flutter

```dart
// Widgets
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user}); // const constructor

  final User user;

  @override
  Widget build(BuildContext context) { ... }
}

// Evite rebuilds desnecessários com const e gerenciamento de estado adequado
```

## Recomendações Finais

- Rode sempre o linter (`analysis_options.yaml`).
- Escreva testes.
- Mantenha widgets pequenos e reutilizáveis.
- Escolha **uma** solução de gerenciamento de estado e seja consistente (ex: Riverpod, Bloc).

**Referência principal**: [Effective Dart](https://dart.dev/effective-dart)

## O que é o `analysis_options.yaml`?

É o arquivo de **configuração do analisador estático do Dart** (o `dart analyze`).

Ele permite que você defina:
- Quais regras do **linter** devem ser ativadas/desativadas
- Quais erros devem ser tratados como warnings ou erros graves
- Regras personalizadas do time/projeto

Esse arquivo é fundamental para manter o código seguindo as **boas práticas** da comunidade Dart/Flutter de forma automática.

Ele fica na raiz do projeto, no mesmo nível do `pubspec.yaml`.

**Como usar?**

No terminal, execute os comandos:

```bash
make shell
dart analyze
```

Ou configure seu editor (VS Code / Android Studio) para analisar automaticamente.