# CI/CD com GitHub Actions

O template vem com um workflow de **build automático** já configurado em `.github/workflows/build.yml`.

## Quando o pipeline roda

O pipeline **só executa** em duas situações:

1. Quando um Pull Request é mergeado na branch `main`.
2. Quando você dispara o workflow manualmente, na aba **Actions**.

Isso evita builds desnecessários em PRs abertos ou pushes em branches de feature.

## Configuração obrigatória

Você precisa configurar um Secret no repositório:

1. Vá em **Settings > Secrets and variables > Actions**.
2. Clique em **New repository secret**.
3. Crie um secret chamado **`PLATFORMS`**.

**Valor exemplo**, com qualquer combinação que você queira buildar:
- `android,ios`
- `android,web,linux`
- `android,ios,web,macos,windows` (todas)

> **Dica:** use o mesmo valor que você colocou no `.env` na criação do projeto.

## O que o pipeline faz

- Detecta automaticamente as plataformas configuradas no Secret `PLATFORMS`.
- Executa só os jobs necessários — por exemplo, se `ios` não estiver na lista, o job correspondente é pulado.
- Gera os artefatos de build para cada plataforma.
- Sobe os artefatos para você baixar na aba **Actions**.

### Builds suportados

| Plataforma | Job no CI | Artefato gerado |
|---|---|---|
| Android | `android` | `app-release.apk` |
| Web | `web` | Pasta `build/web` |
| Linux | `linux` | Executável Linux |
| Windows | `windows` | Pasta com `.exe` |
| macOS | `macos` | App macOS |
| iOS | `ios` | Pasta de build (sem assinatura) |

## Disparando manualmente

1. Vá na aba **Actions** do repositório.
2. Selecione o workflow **Build**.
3. Clique em **Run workflow**.
4. Escolha a branch `main` e confirme.

## Boas práticas

- O `.env` **nunca** deve ser commitado (já está no `.gitignore`).
- O secret `PLATFORMS` é a fonte única da verdade para o CI.
- Builds distribuíveis de iOS (`.ipa`) exigem certificados e provisioning profiles — fora do escopo deste template básico.
- O workflow é otimizado por custo: só roda o que é necessário.

## Próximos passos possíveis

Ideias pra evoluir o pipeline, fora do escopo atual do template:

- Rodar `flutter test` automaticamente no CI.
- Publicar no Google Play / App Store via Fastlane.
- Notificações no Slack/Discord após o build.
- Cache de dependências para builds mais rápidos.