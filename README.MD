# Flutter Skeleton Docker
![Flutter Skeleton Banner](docs/flutter-skeleton-banner.png)

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

## Estrutura do template

```
.
├── Dockerfile  # Imagem com Flutter SDK, Android SDK e toolchain de build
├── compose.yml # Definição do serviço (nome/imagem dinâmicos via PROJECT_NAME)
├── Makefile    # Atalhos para build/up/down/shell/create/etc.
├── install.sh  # Script de bootstrap (clona + configura + cria o projeto)
└── README.md
```

O `compose.yml` usa a variável `PROJECT_NAME` (definida no arquivo `.env`, gerado pelo `install.sh` a partir do nome do projeto digitado pelo usuário) para nomear:

- o **projeto Compose** em si (campo `name:` no topo do arquivo — afeta `docker compose ls` e prefixos padrão internos);
- a **imagem** (`image:`);
- o **container** (`container_name:`);
- os **volumes** de cache do `pub` e do Android SDK.

Ou seja, **um único nome — o que você digita na instalação — propaga para todo o ambiente**, garantindo que cada projeto criado a partir deste template tenha seu próprio container, imagem e volumes isolados, e você pode ter vários projetos rodando ao mesmo tempo na mesma máquina sem conflito de nome. O `Makefile` também lê esse mesmo `PROJECT_NAME` do `.env` (via `-include .env`) e o usa nas mensagens de `build`, `up`, `shell`, `build-app` e no comando `make name`.

Se preferir renomear o container de um projeto já criado, basta editar `PROJECT_NAME` no `.env` e rodar `make down && make up` novamente (isso recria o container/imagem com o novo nome; os volumes antigos de cache não são migrados automaticamente).