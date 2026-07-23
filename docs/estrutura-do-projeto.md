# Estrutura do Projeto

Este template segue **Clean Architecture** (camadas `data` / `domain` /
`presentation`) combinada com **feature-first**: cada funcionalidade do app
vive isolada em `lib/src/features/<feature>/`, com sua própria fatia de
`data`, `domain` e `presentation` — nada é compartilhado entre features por
padrão, a não ser o que for movido deliberadamente para `shared/`.

## Por que essa estrutura

- **`data/datasources`** — fala com o mundo externo (API via Dio, etc.). Uma
  feature sem dependência externa (como a `home` deste template) pode usar
  uma fonte de dados local em vez de remota — o padrão se adapta à
  necessidade real da feature, não o contrário.
- **`data/dtos`** — representação bruta dos dados (JSON/Map), isolada do
  domínio.
- **`data/repositories`** — implementação concreta, faz a ponte DTO → Entity.
- **`domain/entities`** — objetos de negócio puros, sem dependência de
  serialização nem de Flutter.
- **`domain/repositories`** — o contrato (interface) que `data/repositories`
  implementa. O domínio depende apenas dessa abstração, nunca da
  implementação concreta.
- **`domain/usecases`** — uma ação de negócio por classe (Single
  Responsibility). Hoje costuma ser um repasse simples ao repository, mas é
  aqui que entra qualquer regra adicional no futuro.
- **`presentation/controllers`** — o `Notifier` do Riverpod, orquestra
  usecases e expõe o estado para a UI.
- **`presentation/pages`** — a tela.
- **`presentation/widgets`** — pedaços de UI extraídos da página, para
  manter a página enxuta e os widgets testáveis isoladamente.

Todo domínio, do primeiro ao centésimo, segue exatamente essa mesma base —
um dev sênior desenha o padrão uma vez, e qualquer pessoa do time que rodar
`make new-feature` reproduz esse mesmo padrão sem precisar decidir nada.
Veja [Comandos Make](comandos-make.md) para gerar uma feature nova.

## Árvore completa

```bash
lib/
├── main.dart
└── src/
    ├── core/                       # tema, router, di, config
    │   ├── router/
    │   │   └── app_router.dart
    │   └── theme/
    │       └── app_theme.dart
    ├── features/                   # feature-first
    │   └── home/
    │       ├── data/
    │       │   ├── datasources/
    │       │   │   └── home_local_datasource.dart
    │       │   ├── dtos/
    │       │   │   └── home_dto.dart
    │       │   └── repositories/
    │       │       └── home_repository_impl.dart
    │       ├── domain/
    │       │   ├── entities/
    │       │   │   └── home_entity.dart
    │       │   ├── repositories/
    │       │   │   └── home_repository.dart
    │       │   └── usecases/
    │       │       └── get_home_data_usecase.dart
    │       └── presentation/
    │           ├── controllers/
    │           │   └── home_notifier.dart
    │           ├── pages/
    │           │   └── home_page.dart
    │           └── widgets/
    │               └── home_header_widget.dart
    └── shared/                     # widgets, extensions, models comuns

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
│       │   ├── dtos/
│       │   │   └── home_dto_test.dart
│       │   └── repositories/
│       │       └── home_repository_impl_test.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── home_entity_test.dart
│       │   ├── repositories/       # sem teste — é só uma interface,
│       │   │                       # sem lógica própria
│       │   └── usecases/
│       │       └── get_home_data_usecase_test.dart
│       └── presentation/
│           ├── controllers/
│           │   └── home_notifier_test.dart
│           ├── pages/
│           │   └── home_page_test.dart
│           └── widgets/
│               └── home_header_widget_test.dart
└── shared/

integration_test/
└── app_test.dart
```

## `test/` vs `integration_test/`

- **`test/`** roda em ambiente simulado (`flutter_test`) — rápido, sem
  precisar de device/emulador. É onde vive a maioria dos testes (unidade e
  widget).
- **`integration_test/`** sobe o app de verdade (motor de renderização
  real — device, emulador ou build desktop/web). Deve ficar enxuto: fluxos
  de ponta a ponta que atravessam mais de uma feature, não uma repetição
  dos testes de widget que já existem em `test/`.