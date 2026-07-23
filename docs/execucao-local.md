# Execução local

Depois de subir o ambiente (`make up` e `make shell`), você pode rodar o projeto diretamente com os comandos do Flutter, escolhendo a plataforma desejada.

## Listar dispositivos/plataformas disponíveis

```bash
flutter devices
```

## Android

```bash
flutter run -d android
```

## Linux (Desktop)

> O compartilhamento do X11 com o container já vem configurado no `compose.yml`
> (`DISPLAY`, socket `/tmp/.X11-unix` e `network_mode: host`). Você só precisa
> garantir que o container tenha permissão para acessar o servidor X11 do host:
>
> ```bash
> xhost +local:docker
> ```

```bash
flutter run -d linux
```

## Web

```bash
flutter run -d chrome
```

## iOS

> Requer Xcode instalado nativamente em um Mac. Não é possível rodar via
> Docker/Linux — este comando deve ser executado fora do container, em uma
> máquina macOS com o toolchain do Xcode configurado.

```bash
flutter run -d ios
```

## macOS (Desktop)

> Requer Xcode instalado nativamente em um Mac. Assim como o iOS, não roda
> via Docker/Linux — execute fora do container, em uma máquina macOS.

```bash
flutter run -d macos
```

## Windows (Desktop)

> Requer Visual Studio com "Desktop development with C++" instalado
> nativamente no Windows. Não roda via Docker/Linux — execute fora do
> container, em uma máquina Windows.

```bash
flutter run -d windows
```

> **Nota:** iOS, macOS e Windows podem ser selecionados em `PLATFORMS`
> durante a criação do projeto (`install.sh`) para fazer parte do escopo do
> app e dos builds de CI (ver [Build Multi-plataforma](ci-cd.md)), mas o
> `flutter run` local para elas precisa acontecer fora do ambiente Docker
> deste template, na máquina nativa correspondente.

## Rodando em modo release

Para testar uma build de produção localmente:

```bash
flutter run --release -d <plataforma>
```

Substitua `<plataforma>` por `android`, `linux`, `chrome`, `ios`, `macos` ou `windows`.

## Testes de integração

Diferente do `flutter run`, os testes de `integration_test/` sobem o app
real dentro do próprio comando de teste:

```bash
flutter test integration_test/app_test.dart -d linux
```