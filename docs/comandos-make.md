# Comandos Make

| Comando | Descrição |
|---|---|
| `make build` | Builda a imagem Docker |
| `make up` | Sobe o container |
| `make down` | Para o container |
| `make shell` | Abre um shell dentro do container |
| `make analyze` | Executa a análise estática (`dart analyze`) |
| `make format` | Formata o código (`dart format`) |
| `make fix` | Aplica correções automáticas sugeridas pelo linter |
| `make gen` | Gera código (Freezed, Riverpod, etc.) via `build_runner` |
| `make test` | Executa os testes em `test/` |
| `make new-feature name="X"` | Gera uma nova feature completa (Feature + DDD, lib + testes) |
| `make build-app` | Gera builds de release (Android + Linux) |
| `make clean` | Remove o container e os caches |

## `make new-feature`

Gera a estrutura padrão do template (`data` / `domain` / `presentation`) para uma nova feature, junto com o espelho de testes correspondente em `test/`.

```bash
make new-feature name="Estoque"
make new-feature name="Exportação de produtos"
make new-feature              # pergunta o nome interativamente
```

O que é gerado, e por quê, está detalhado em [Estrutura do Projeto](estrutura-do-projeto.md). Se a feature crescer e precisar de mais camadas (`usecase`, domain service), veja [Usecases e Domain Services](usecases-e-domain-services.md) — isso não é gerado automaticamente, é uma decisão que você toma quando a lógica realmente pedir.