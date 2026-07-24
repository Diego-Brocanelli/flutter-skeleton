# Usecases e Domain Services: quando e como criar

O Flutter Skeleton começa **enxuto de propósito**: toda feature nova (`make new-feature`) gera só `data/ domain/ presentation/`, sem `usecases` nem domain services. Essa é a base mínima pra times pequenos ou projetos individuais começarem sem atrito. Este documento explica **quando** vale sair desse mínimo e **como** fazer isso corretamente.

Se você chegou aqui se perguntando "minha lógica deveria estar em um usecase, um domain service, ou nem isso?", comece pela árvore de decisão abaixo.

## Árvore de decisão

```
A lógica só repassa a chamada pro repository, sem mais nada?
├─ Sim → Não cria nada. O Notifier chama o repository direto.
└─ Não → Tem lógica de verdade. Ela precisa de I/O (repository, API, banco)?
    ├─ Sim → Usecase
    └─ Não → Precisa de mais de uma entidade pra fazer sentido?
        ├─ Sim → Domain Service
        └─ Não → Provavelmente é um método/getter na própria Entity
```

## O básico: sem usecase, sem domain service

```
features/estoque/
├── data/
│   ├── datasources/
│   │   └── estoque_local_datasource.dart
│   └── repositories/
│       └── estoque_repository_impl.dart   # busca, converte e implementa a interface
├── domain/
│   ├── entities/
│   │   └── estoque_entity.dart
│   └── repositories/
│       └── estoque_repository.dart        # interface
└── presentation/
    ├── notifiers/
    │   └── estoque_notifier.dart          # chama o repository direto
    ├── pages/
    │   └── estoque_page.dart
    └── widgets/
```

```dart
class EstoqueNotifier extends AsyncNotifier<EstoqueEntity?> {
  @override
  Future<EstoqueEntity?> build() {
    return ref.read(estoqueRepositoryProvider).getEstoqueData();
  }
}
```

Isso é suficiente pra maioria das telas: listagem, cadastro simples, detalhe. Não crie nada além disso "por padrão" ou "pra parecer mais robusto" — crie quando a lógica realmente pedir.

## Usecase: quando criar

Um usecase é uma classe = uma ação de negócio que **orquestra I/O** (repository, API, banco, sensores, etc.). Se o método só repassa pro repository sem fazer nada a mais, não é usecase — é decoração.

| Situação | Usecase? |
|---|---|
| `getEstoqueData()` chama `repository.getEstoqueData()` e retorna | ❌ |
| Combina 2+ fontes (ex.: dado local + verificação de conectividade) | ✅ |
| Tem regra de validação ou cálculo antes/depois do I/O | ✅ |
| Orquestra múltiplos passos com efeito colateral (ex.: sync — busca API → grava local → limpa fila pendente) | ✅ |

### Como projetar um usecase

- Um método público, geralmente `call()` — permite chamar como `usecase()`.
- Recebe o repository (a **interface**, nunca a implementação) via construtor.
- Não conhece Flutter, não conhece `Notifier` — só orquestra o `domain`.

```dart
class SincronizarEstoqueUsecase {
  const SincronizarEstoqueUsecase(this._repository);

  final EstoqueRepository _repository;

  Future<void> call() async {
    final pendentes = await _repository.getPendentesDeSync();
    if (pendentes.isEmpty) return;

    await _repository.enviarParaApi(pendentes);
    await _repository.marcarComoSincronizado(pendentes);
  }
}
```

### Onde colocar

Não crie a pasta `usecases/` por padrão. Coloque o arquivo solto dentro de `domain/`, e só promova para uma subpasta se a feature acumular vários:

```
features/estoque/
└── domain/
    ├── entities/
    │   └── estoque_entity.dart
    ├── repositories/
    │   └── estoque_repository.dart
    └── sincronizar_estoque_usecase.dart   ← só quando fizer sentido
```

## Domain Service: quando criar

Um Domain Service é **lógica de negócio pura entre duas ou mais entidades** — sem I/O, sem repository, sem saber que banco ou API existem. É isso que o torna testável sem nenhum mock, só passando objetos.

| | Usecase | Domain Service |
|---|---|---|
| O que faz | Orquestra: chama repository, coordena I/O | Lógica de negócio pura entre entidades |
| Depende de repository? | Sim | Não |
| Exemplo | `SincronizarEstoqueUsecase` (busca na API, grava local) | `TransferenciaEstoqueService` (move quantidade entre dois `EstoqueEntity`, garante que nenhum fique negativo) |

Se um "Domain Service" começa a receber um `repository` no construtor, ele virou usecase disfarçado — mova a lógica pura pra dentro e deixe o I/O na camada de usecase.

```dart
// Domain Service — puro, sem I/O
class TransferenciaEstoqueService {
  const TransferenciaEstoqueService();

  (EstoqueEntity, EstoqueEntity) transferir({
    required EstoqueEntity origem,
    required EstoqueEntity destino,
    required int quantidade,
  }) {
    if (origem.quantidade < quantidade) {
      throw EstoqueInsuficienteException();
    }
    return (
      origem.copyWith(quantidade: origem.quantidade - quantidade),
      destino.copyWith(quantidade: destino.quantidade + quantidade),
    );
  }
}

// Usecase — orquestra, tem I/O, usa o Domain Service acima
class TransferirEstoqueUsecase {
  const TransferirEstoqueUsecase(this._repository, this._service);

  final EstoqueRepository _repository;
  final TransferenciaEstoqueService _service;

  Future<void> call({
    required String origemId,
    required String destinoId,
    required int qtd,
  }) async {
    final origem = await _repository.getById(origemId);
    final destino = await _repository.getById(destinoId);

    final (novaOrigem, novoDestino) = _service.transferir(
      origem: origem,
      destino: destino,
      quantidade: qtd,
    );

    await _repository.salvar(novaOrigem);
    await _repository.salvar(novoDestino);
  }
}
```

### Onde colocar

Mesma regra do usecase — arquivo solto em `domain/`, sem pasta dedicada por padrão:

```
features/estoque/
└── domain/
    ├── entities/
    │   └── estoque_entity.dart
    ├── repositories/
    │   └── estoque_repository.dart
    ├── sincronizar_estoque_usecase.dart
    └── transferencia_estoque_service.dart
```

### Convenção de nome

Pra não confundir os dois dentro da mesma pasta `domain/`:

- `_usecase.dart` — orquestração, tem I/O (depende de repository).
- `_service.dart` — lógica pura, sem I/O (só entities).

## Resumo

- **Padrão:** `data/ domain/ presentation/`, sem mais nada. O `Notifier` chama o `repository` direto.
- **Usecase:** quando a lógica precisa de I/O além de um repasse simples (combina fontes, valida, orquestra múltiplos passos).
- **Domain Service:** quando a lógica é pura (sem I/O) e envolve mais de uma entidade.
- Os dois ficam soltos dentro de `domain/`, sem subpasta obrigatória — a estrutura cresce com a necessidade real da feature, não por padrão.

Veja também: [Estrutura do Projeto](estrutura-do-projeto.md) para o desenho completo de uma feature.