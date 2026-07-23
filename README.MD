# Flutter Skeleton
![Flutter Skeleton banner](docs/flutter-skeleton-banner.png)

**Template opinativo e moderno para Flutter** com ambiente completo em Docker.

## Sumário

- [Introdução](#introdução)
- [Stack Tecnológica](#stack-tecnológica)
- [Requisitos](#requisitos)
- [Como usar](#como-usar)
- [Documentação completa](#documentação-completa)

## Introdução

Este repositório é um **template completo** para iniciar projetos Flutter de forma rápida e consistente.

Tudo roda dentro de um **container Docker** isolado, sem necessidade de instalar Flutter, Android SDK ou outras ferramentas diretamente na máquina host.

**Principais vantagens:**
- Ambiente 100% reprodutível.
- Suporte nativo a múltiplas plataformas.
- Stack moderna e opinativa (Riverpod + go_router + Freezed).
- Clean Architecture (data/domain/presentation) já aplicada, com geração automática de novas features via `make new-feature`.
- CI/CD pronto com GitHub Actions.
- Fácil de ter vários projetos rodando simultaneamente.

## Stack Tecnológica

- **Gerenciamento de Estado**: [Riverpod](https://riverpod.dev/) (com [`riverpod_annotation`](https://pub.dev/packages/riverpod_annotation))
- **Navegação**: [go_router](https://pub.dev/packages/go_router)
- **HTTP**: [Dio](https://pub.dev/packages/dio) + [Retrofit](https://pub.dev/packages/retrofit)
- **Modelos**: [Freezed](https://pub.dev/packages/freezed) + [json_serializable](https://pub.dev/packages/json_serializable)
- **Injeção de Dependência**: [Riverpod](https://riverpod.dev/)
- **Logging**: [logger](https://pub.dev/packages/logger)
- **Geração de Código**: [build_runner](https://pub.dev/packages/build_runner)
- **Outros**:
  - [flutter_native_splash](https://pub.dev/packages/flutter_native_splash)
  - [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)

## Requisitos

- Linux (testado em Fedora e Ubuntu).
- Docker + Docker Compose v2.
- `git` e `make`.
- Servidor X11 (para desktop Linux).

> **macOS / Windows**: Use WSL2 (Linux) ou adapte o `compose.yml`.

## Como usar

### 1. Criar um novo projeto (recomendado)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/main/install.sh)
```

O script vai:
1. Perguntar nome do projeto.
2. Perguntar plataformas desejadas.
3. Clonar, configurar e criar o projeto com a stack completa (Clean Architecture + testes já aplicados).
4. Abrir o shell dentro do container.

### 2. Comandos do dia a dia

```bash
make up                        # Subir container
make shell                     # Entrar no container
make analyze                   # Análise estática
make format                    # Formatar código
make new-feature name="Nome"   # Gerar uma nova feature completa (lib + testes)
```

Lista completa de comandos: [Comandos Make](docs/comandos-make.md).

## Documentação completa

Guias detalhados ficam em [`/docs`](docs/):

- [Comandos Make](docs/comandos-make.md) — todos os targets disponíveis.
- [Estrutura do Projeto](docs/estrutura-do-projeto.md) — como a Clean Architecture é organizada aqui, e o que `make new-feature` gera.
- [Boas Práticas](docs/boas-praticas.md) — convenções de código (Effective Dart), recomendações finais e o papel do `analysis_options.yaml`.
- [Execução local](docs/execucao-local.md) — como rodar o app em cada plataforma suportada.
- [Build Multi-plataforma (CI)](docs/ci-cd.md) — como funciona o CI/CD com GitHub Actions.