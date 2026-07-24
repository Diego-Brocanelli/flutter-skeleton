# Execução Local

Depois de subir o ambiente (`make up` e `make shell`), você roda o projeto normalmente com os comandos do Flutter, escolhendo a plataforma desejada.

## Listar dispositivos e plataformas disponíveis

```bash
flutter devices
```

## Android

```bash
flutter run -d android
```

## Linux (desktop)

O compartilhamento do X11 com o container já vem configurado no `compose.yml` (`DISPLAY`, socket `/tmp/.X11-unix` e `network_mode: host`). Você só precisa garantir que o container tenha permissão para acessar o servidor X11 do host:

```bash
xhost +local:docker
```

Depois:

```bash
flutter run -d linux
```

## Web

```bash
flutter run -d chrome
```

## iOS

> Requer Xcode instalado nativamente em um Mac. Não roda via Docker/Linux — execute fora do container, numa máquina macOS com o toolchain do Xcode configurado.

```bash
flutter run -d ios
```

## macOS (desktop)

> Requer Xcode instalado nativamente em um Mac. Assim como o iOS, não roda via Docker/Linux — execute fora do container.

```bash
flutter run -d macos
```

## Windows (desktop)

> Requer Visual Studio com "Desktop development with C++" instalado nativamente no Windows. Não roda via Docker/Linux — execute fora do container.

```bash
flutter run -d windows
```

> **Nota:** iOS, macOS e Windows podem ser selecionados em `PLATFORMS` durante a criação do projeto (`install.sh`) para fazer parte do escopo do app e dos builds de CI (veja [CI/CD](ci-cd.md)) — mas o `flutter run` local para essas três plataformas precisa acontecer fora do ambiente Docker deste template, direto na máquina nativa correspondente.

## Rodando em modo release

```bash
flutter run --release -d <plataforma>
```

Substitua `<plataforma>` por `android`, `linux`, `chrome`, `ios`, `macos` ou `windows`.

## Testes de integração

Diferente do `flutter run`, os testes de `integration_test/` sobem o app real dentro do próprio comando de teste:

```bash
flutter test integration_test/app_test.dart -d linux
```