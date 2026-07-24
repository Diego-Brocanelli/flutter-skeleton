# Estrutura do Projeto

O Flutter Skeleton organiza o código por **Feature + DDD** (Domain-Driven Design): cada funcionalidade do app vive isolada em `lib/src/features/<feature>/`, com sua própria fatia de `data`, `domain` e `presentation`. Nada é compartilhado entre features por padrão — só o que for movido deliberadamente para `shared/`.

A estrutura gerada é **enxuta de propósito**. Ela cobre o que toda feature precisa (fonte de dados, entidade, contrato, tela, estado), sem forçar camadas extras (`usecases`, domain services) que a maioria das telas simples não precisa. Quando uma feature crescer o suficiente para justificar isso, veja [Usecases e Domain Services](usecases-e-domain-services.md).

## As três camadas

| Camada | Pastas | Responsabilidade |
|---|---|---|
| `data` | `datasources/`, `repositories/` | Busca e converte dados — de uma API, de um banco local, ou de onde fizer sentido |
| `domain` | `entities/`, `repositories/` | O núcleo de negócio: objetos puros e o contrato que `data` implementa |
| `presentation` | `notifiers/`, `pages/`, `widgets/` | Estado (via Riverpod) e UI |

### `data/datasources`

Fala com o mundo externo: uma API via Dio, um banco local, um arquivo, etc. Uma feature sem dependência externa (como a `home` deste template) pode usar uma fonte de dados **local** em vez de remota — a estrutura se adapta à necessidade real da feature, não o contrário.

### `data/repositories`

Implementação concreta de `domain/repositories`. Busca o dado bruto no datasource e já devolve a `Entity` pronta — a conversão (JSON/Map → Entity) acontece aqui mesmo, sem precisar de uma classe de DTO separada. Se o payload da sua API for complexo o suficiente para justificar uma camada própria de conversão, você pode adicionar isso depois; não é o padrão default.

### `domain/entities`

Objetos de negócio puros: sem anotação de serialização, sem depender de Flutter, sem depender de `data` ou `presentation`.

### `domain/repositories`

O contrato (interface) que `data/repositories` implementa. O domínio depende **só** dessa abstração — nunca da implementação concreta. É o que torna o `Notifier` testável sem precisar de banco nem de HTTP: basta mockar o repository.

### `presentation/notifiers`

O `AsyncNotifier` do Riverpod. Chama o repository (direto, na maioria dos casos) e expõe o estado para a UI. Não deve conter regra de negócio — isso é papel do `domain`.

### `presentation/pages`

A tela.

### `presentation/widgets`

Pedaços de UI extraídos da página, mantendo `pages/` enxuta e cada widget testável isoladamente.

## Árvore completa

```bash
lib/
├── main.dart
└── src/
    ├── core/                       # tema, router, DI, config
    │   ├── router/
    │   │   └── app_router.dart
    │   └── theme/
    │       └── app_theme.dart
    ├── features/                   # feature-first
    │   └── home/
    │       ├── data/
    │       │   ├── datasources/
    │       │   │   └── home_local_datasource.dart
    │       │   └── repositories/
    │       │       └── home_repository_impl.dart
    │       ├── domain/
    │       │   ├── entities/
    │       │   │   └── home_entity.dart
    │       │   └── repositories/
    │       │       └── home_repository.dart
    │       └── presentation/
    │           ├── notifiers/
    │           │   └── home_notifier.dart
    │           ├── pages/
    │           │   └── home_page.dart
    │           └── widgets/
    │               └── home_header_widget.dart
    └── shared/                     # widgets, extensions, models comuns (vazio até a 1ª feature precisar)

test/
├── app_test.dart
├── core/
│   ├── router/
│   │   └── app_router_test.dart
│   └── theme/
│       └── app_theme_test.dart
├── features/
│   └── home/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── home_local_datasource_test.dart
│       │   └── repositories/
│       │       └── home_repository_impl_test.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── home_entity_test.dart
│       │   └── repositories/       # sem teste — é só uma interface,
│       │                           # sem lógica própria
│       └── presentation/
│           ├── notifiers/
│           │   └── home_notifier_test.dart
│           ├── pages/
│           │   └── home_page_test.dart
│           └── widgets/
│               └── home_header_widget_test.dart
└── shared/

integration_test/
└── app_test.dart
```

## A feature `home`: exemplo de referência

A feature `home`, incluída no template, existe para **demonstrar o fluxo completo em código real** — não é só um placeholder. Ela usa um datasource local (não uma API), porque a tela de boas-vindas não depende de nada externo; isso já ilustra que a estrutura se adapta à necessidade da feature, não o contrário.

Quer entender como as camadas conversam entre si? A ordem de chamada é sempre a mesma:

```
Page → Notifier → Repository (interface) → RepositoryImpl → DataSource
```

E o retorno (a `Entity`) sobe pela mesma cadeia, camada a camada, até chegar na UI.

## `test/` vs `integration_test/`

- **`test/`** roda em ambiente simulado (`flutter_test`) — rápido, sem precisar de device ou emulador. É onde vive a maioria dos testes (unidade e widget).
- **`integration_test/`** sobe o app de verdade (motor de renderização real — device, emulador ou build desktop/web). Deve ficar enxuto: fluxos de ponta a ponta que atravessam mais de uma feature, não uma repetição dos testes de widget que já existem em `test/`.

## Gerando uma feature nova

```bash
make new-feature name="Estoque"
```

Isso gera essa mesma estrutura (lib + testes espelhados) para a feature `estoque`. Veja [Comandos Make](comandos-make.md) para detalhes.