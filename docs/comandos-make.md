# Comandos Make

| Comando                       | Descrição                                        |
|--------------------------------|--------------------------------------------------|
| `make build`                  | Builda a imagem Docker                            |
| `make up`                     | Sobe o container                                  |
| `make down`                   | Para o container                                  |
| `make shell`                  | Abre shell dentro do container                    |
| `make analyze`                | Executa análise estática                          |
| `make format`                 | Formata o código                                  |
| `make fix`                    | Aplica correções automáticas                      |
| `make gen`                    | Gera código (Freezed, Riverpod, etc.)             |
| `make test`                   | Executa testes                                    |
| `make new-feature name="X"`   | Gera uma nova feature completa (Clean Architecture, lib + testes) |
| `make build-app`              | Gera builds de release (Android + Linux)          |
| `make clean`                  | Remove container e caches                         |

## `make new-feature`

Gera a estrutura Clean Architecture completa (`data` / `domain` / `presentation`)
para uma nova feature, junto com o espelho de testes correspondente em `test/`.

```bash
make new-feature name="Estoque"
make new-feature name="Exportação de produtos"
make new-feature              # pergunta o nome interativamente
```

Veja o detalhe de tudo o que é gerado em [Estrutura do Projeto](estrutura-do-projeto.md).