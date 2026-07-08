# Flutter Skeleton

## Sumário
- [Introdução](#introdução)
- [Requisitos](#requisitos)
- [Como usar](#como-usar)
- [Comandos make disponíveis](#comandos-make-disponíveis)
- [Build multi plataforma via GitHub actions](#build-multi-plataforma-via-github-actions)
- [Estrutura do template](#estrutura-do-template)
- Complementos
    - [Boas Práticas](#boas-práticas)

## Introdução

Este repositório é um **template base para iniciar qualquer projeto Flutter** sem precisar instalar Flutter, Android SDK, Java ou dependências de build diretamente na sua máquina. Tudo roda dentro de um container Docker isolado e reprodutível, com:

- Flutter SDK (canal `stable` por padrão)
- Android SDK + `adb`/`fastboot` (para builds e deploy Android)
- Suporte a build desktop Linux (GTK, CMake, Ninja, clang)
- Suporte a X11 (para abrir apps GUI do container na sua tela, via `DISPLAY`)
- Usuário não-root espelhando seu UID/GID (evita problemas de permissão nos arquivos do projeto)

A ideia é: você roda um único comando, informa o nome do projeto e as plataformas desejadas, e já recebe um projeto Flutter pronto, com o ambiente de desenvolvimento completo rodando em container e um shell aberto dentro dele.

## Requisitos

Na sua máquina host (Linux), você precisa apenas de:

- [Docker](https://docs.docker.com/engine/install/) e [Docker Compose v2](https://docs.docker.com/compose/install/) (`docker compose`, sem hífen)
- `git`
- `make`
- Servidor X11 ativo, se quiser rodar apps desktop Linux com interface gráfica a partir do container (a maioria das distros já vem com isso)
- Acesso a `/dev/bus/usb` para usar `adb` com dispositivo Android físico (o container roda em modo `privileged` para enxergar o USB)

> O template foi desenvolvido e testado em Linux (Fedora/Ubuntu). Como usa `network_mode: host` e bind mount de `/tmp/.X11-unix`, ele **não funciona nativamente no macOS ou Windows** (nesses casos, use WSL2 com um servidor X ou adapte o `compose.yml`).

## Como usar

### 1. Criar um novo projeto a partir do template

Execute o script de instalação diretamente do GitHub. Use `bash <(...)` em vez de um pipe (`| bash`), para que os prompts interativos funcionem corretamente:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/main/install.sh)
```

ou, com `wget`:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/main/install.sh)
```

O script vai:

1. Perguntar o **nome do projeto** e clonar o template para uma pasta com esse nome
2. Gerar, a partir do nome informado, o **nome do container/imagem Docker** (mesmo nome, normalizado para o formato aceito pelo Docker) e checar se já não existe um container com esse nome
3. Perguntar quais **plataformas** o projeto deve suportar (Android, iOS, Web, Linux, Windows, macOS)
4. Buildar a imagem Docker (`make build`)
5. Subir o container já nomeado com o nome do projeto (`make up`) — isso é o que permite criar **vários projetos em paralelo, cada um com seu próprio container, imagem e volumes de cache, sem conflitar entre si**
6. Rodar `flutter create --platforms=...` dentro do container, gerando a estrutura inicial do projeto
7. Abrir um shell (`make shell`) dentro do container, pronto para você trabalhar

> **Nome do container vs. nome do pacote Flutter:** o container/imagem/volumes usam o nome do projeto exatamente como você digitou (só normalizado para o formato do Docker, ex.: `Meu Projeto` → `meu-projeto`). Já o pacote Dart criado pelo `flutter create` precisa seguir a convenção `snake_case` do Dart (ex.: `meu_projeto`) — o script gera essa segunda variação automaticamente, sem afetar o nome do container.

> **Observação sobre plataformas:** este container roda Linux, então ele consegue **gerar a estrutura** de projetos iOS, Windows e macOS, mas **não compila** esses alvos (builds nativos exigem, respectivamente, um host macOS com Xcode ou um host/CI Windows com MSVC). Android e Linux desktop são totalmente suportados dentro do container.

### 2. Trabalhando no dia a dia

Depois do projeto criado, use os comandos `make` (veja a seção abaixo) a partir da pasta do projeto. Exemplos comuns:

```bash
make up          # sobe o container (se estiver parado)
make shell       # entra no shell do container
```

Dentro do shell do container, use o Flutter normalmente:

```bash
flutter pub get
flutter run -d linux      # rodar o app desktop
flutter run -d <device-id> # rodar em dispositivo Android via adb
```

#### Rodando a versão Web

Se você selecionou a plataforma `web` na instalação, rode:

```bash
flutter run -d chrome
```

Isso compila e roda o app no Chrome, com hot reload via servidor de desenvolvimento do Flutter. Algumas variações úteis:

```bash
flutter run -d chrome --web-port=8080   # escolher outra porta
flutter run -d chrome --release         # build otimizado (release)
flutter devices                         # listar dispositivos disponíveis (chrome, web-server, etc.)
```

> **Container sem o Chrome instalado?** Nesse caso use o modo `web-server` em vez de `chrome`:
> ```bash
> flutter run -d web-server --web-port=8080
> ```
> Como o container roda com `network_mode: host`, a porta fica acessível diretamente pela sua máquina host, sem precisar mapear portas — basta abrir `http://localhost:8080` no navegador do seu computador.

### 3. Usando o template manualmente (sem o install.sh)

Se preferir não usar o script, você pode clonar o repositório e configurar manualmente:

```bash
git clone https://github.com/Diego-Brocanelli/flutter-skeleton.git meu-projeto
cd meu-projeto
rm -rf .git && git init

echo "PROJECT_NAME=meu_projeto" > .env
echo "PLATFORMS=android,linux" >> .env

make build
make up
make create PLATFORMS=android,linux
make shell
```

## Comandos make disponíveis

| Comando | Descrição |
|---|---|
| `make build` | Builda a imagem Docker do ambiente de desenvolvimento |
| `make up` | Sobe o container em background (também libera acesso X11 via `xhost`) |
| `make down` | Para e remove o container |
| `make dow` | Alias de `make down` (atalho para digitação) |
| `make shell` | Abre um shell `bash` dentro do container |
| `make create` | Roda `flutter create` no diretório do projeto usando `PLATFORMS` (padrão: `android,linux`). Ex.: `make create PLATFORMS=android,web` |
| `make doctor` | Roda `flutter doctor -v` dentro do container, para diagnosticar o ambiente |
| `make logs` | Mostra os logs do container em tempo real |
| `make ps` | Lista o(s) container(s) do projeto |
| `make name` | Mostra o nome do projeto/container atual (lido do `.env`) |
| `make build-app` | Gera builds de release: Linux desktop e Android (APK). Windows precisa de host/CI separado, conforme aviso no próprio comando |
| `make clean` | Remove o container **e os volumes** (cache do `pub` e do Android SDK/`adb`) deste projeto |

Todos os comandos (exceto `build-app`, que roda dentro do container) leem `PROJECT_NAME` do `.env` automaticamente, então nunca é preciso passar o nome do projeto manualmente — o `Makefile` já sabe qual container/imagem usar. Se o `.env` não existir (ex.: você clonou o template manualmente sem rodar `install.sh`), o padrão `flutter-dev` é usado.

## Build multi-plataforma via GitHub Actions

O template já vem com um workflow em `.github/workflows/build.yml` que builda automaticamente **apenas as plataformas que você selecionou na instalação** — sem precisar editar nada.

### Como funciona

1. O `install.sh` grava a plataforma escolhida em `PLATFORMS` no `.env` **local** (usado só pelo Docker/Makefile — nunca é commitado, já está no `.gitignore`).
2. Você configura os mesmos valores como **Secrets do repositório no GitHub** (passo a passo abaixo) — é de lá que o workflow lê a informação.
3. O workflow dispara em apenas dois casos: **quando um Pull Request é mergeado na `main`**, ou **manualmente** pela aba **Actions** do GitHub (botão "Run workflow"). PRs apenas abertos/atualizados, fechados sem merge, e pushes diretos em outras branches, não disparam o build.
4. Um job `detect-platforms` lê o secret `PLATFORMS` e liga/desliga os jobs de build correspondentes.
5. Cada plataforma selecionada builda em paralelo, no runner adequado, e o resultado fica disponível como **artifact** para download na página da execução do workflow:

| Plataforma | Runner | Comando | Artifact |
|---|---|---|---|
| Android | `ubuntu-latest` | `flutter build apk --release` | `<PROJECT_NAME>-android-apk` |
| Web | `ubuntu-latest` | `flutter build web --release` | `<PROJECT_NAME>-web-build` |
| Linux | `ubuntu-latest` | `flutter build linux --release` | `<PROJECT_NAME>-linux-build` |
| Windows | `windows-latest` | `flutter build windows --release` | `<PROJECT_NAME>-windows-build` |
| macOS | `macos-latest` | `flutter build macos --release` | `<PROJECT_NAME>-macos-build` |
| iOS | `macos-latest` | `flutter build ios --release --no-codesign` | `<PROJECT_NAME>-ios-build` |

> **iOS sem assinatura:** o build de iOS no CI é gerado com `--no-codesign`, ou seja, compila e valida o projeto, mas não gera um `.ipa` assinado pronto para a App Store. Para distribuir de fato, é preciso configurar certificados/provisioning profiles como *secrets* adicionais do repositório — avise se quiser ajuda para configurar isso.

> **Windows e macOS/iOS não compilam localmente no container Docker** (que é Linux) — é exatamente para isso que existe este workflow: os runners `windows-latest` e `macos-latest` do GitHub Actions têm o Visual Studio e o Xcode necessários já pré-instalados.

### Configurando os Secrets no GitHub (obrigatório)

O `.env` é local e **nunca é commitado**, então o workflow precisa que você configure manualmente os mesmos valores como Secrets do repositório, uma única vez:

1. No GitHub, abra seu repositório e vá em **Settings > Secrets and variables > Actions**.
2. Clique em **New repository secret** e crie:
   - **Nome:** `PLATFORMS` — **Valor:** o mesmo do seu `.env`, ex. `android,web,linux,windows`
   - **Nome:** `PROJECT_NAME` *(opcional)* — **Valor:** o mesmo do seu `.env`, ex. `meu_app`. Usado só para nomear os artifacts gerados; se omitido, os artifacts saem com o prefixo `app-`.
3. Pronto — não precisa editar o `build.yml`.

> **Por que Secret, e não um valor visível no arquivo?** Isso evita que a configuração fique espalhada em arquivos versionados e mantém uma única fonte de configuração por repositório, gerenciada pelo próprio GitHub. Como consequência, o valor de `PLATFORMS` aparece mascarado (`***`) nos logs do workflow — é esperado, não é um erro.

### Ajustando as plataformas depois

Se quiser mudar quais plataformas o CI builda, edite o Secret `PLATFORMS` em **Settings > Secrets and variables > Actions** (não dá para "editar" um secret existente — é preciso apagar e recriar com o novo valor). Não é preciso mexer no `build.yml`. Lembre-se de atualizar também o `.env` local, para manter os dois em sincronia.

## Estrutura do template

```
.
├── .github/
│   └── workflows/
│       └── build.yml   # CI: builda as plataformas selecionadas (via Secrets do GitHub)
├── .gitignore          # Garante que .env local nunca seja commitado
├── Dockerfile          # Imagem com Flutter SDK, Android SDK e toolchain de build
├── compose.yml         # Definição do serviço (nome/imagem dinâmicos via PROJECT_NAME)
├── Makefile            # Atalhos para build/up/down/shell/create/etc.
├── install.sh          # Script de bootstrap (clona + configura + cria o projeto)
└── README.md
```

O `compose.yml` usa a variável `PROJECT_NAME` (definida no arquivo `.env`, gerado pelo `install.sh` a partir do nome do projeto digitado pelo usuário) para nomear:

- o **projeto Compose** em si (campo `name:` no topo do arquivo — afeta `docker compose ls` e prefixos padrão internos);
- a **imagem** (`image:`);
- o **container** (`container_name:`);
- os **volumes** de cache do `pub` e do Android SDK.

Ou seja, **um único nome — o que você digita na instalação — propaga para todo o ambiente**, garantindo que cada projeto criado a partir deste template tenha seu próprio container, imagem e volumes isolados, e você pode ter vários projetos rodando ao mesmo tempo na mesma máquina sem conflito de nome. O `Makefile` também lê esse mesmo `PROJECT_NAME` do `.env` (via `-include .env`) e o usa nas mensagens de `build`, `up`, `shell`, `build-app` e no comando `make name`.

Se preferir renomear o container de um projeto já criado, basta editar `PROJECT_NAME` no `.env` e rodar `make down && make up` novamente (isso recria o container/imagem com o novo nome; os volumes antigos de cache não são migrados automaticamente).

## Complementos

### Boas práticas

**✅ Boas Práticas da Comunidade Dart (Effective Dart)**

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

### 4. Estrutura de Projeto (Recomendada)

```bash
lib/
  meu_app.dart                 # Biblioteca principal
  src/
    core/                      # configurações, temas, di, etc.
    features/
      auth/
        data/
        domain/
        presentation/
    shared/                    # widgets, utils, extensions
test/
```

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

### Recomendações Finais
- Rode sempre o linter (`analysis_options.yaml`).
- Escreva testes.
- Mantenha widgets pequenos e reutilizáveis.
- Escolha **uma** solução de gerenciamento de estado e seja consistente (ex: Riverpod, Bloc).

**Referência principal**: [Effective Dart](https://dart.dev/effective-dart)

### O que é o `analysis_options.yaml`?

É o arquivo de **configuração do analisador estático do Dart** (o `dart analyze`).

Ele permite que você defina:
- Quais regras do **linter** devem ser ativadas/desativadas
- Quais erros devem ser tratados como warnings ou erros graves
- Regras personalizadas do time/projeto

Esse arquivo é fundamental para manter o código seguindo as **boas práticas** da comunidade Dart/Flutter de forma automática.

Ele fica na raiz do projeto mesmo nível do `pubspec.yaml`).

**Como usar?**

No terminal, execute os comandos.

```bash
make shell
dart analyze
```

Ou configure seu editor (VS Code / Android Studio) para analisar automaticamente.
