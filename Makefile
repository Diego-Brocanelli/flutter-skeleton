# SERVICE é o nome do serviço no docker-compose.yml (fixo, não muda por projeto).
# O nome do CONTAINER/IMAGEM, esse sim, vem de PROJECT_NAME (definido no .env
# pelo install.sh, com o nome do projeto escolhido pelo usuário).
SERVICE := flutter-dev

# Carrega PROJECT_NAME e PLATFORMS do .env gerado pelo install.sh, se existir.
-include .env
PROJECT_NAME ?= flutter-dev

# PLATFORMS pode ser sobrescrito: make create PLATFORMS=android,web
PLATFORMS ?= android,linux

UID := $(shell id -u)
GID := $(shell id -g)
export UID
export GID

.PHONY: build up down dow shell create doctor logs ps clean build-app name analyze format fix test gen

# ====================== Comandos Docker ======================

build:
	@echo ">> Buildando imagem '$(PROJECT_NAME)'..."
	docker compose build

up:
	@xhost +local:docker >/dev/null 2>&1 || true
	docker compose up -d
	@echo ">> Container '$(PROJECT_NAME)' rodando."

down:
	docker compose down

# Alias para "down" (mantido caso você digite "dow" por engano)
dow: down

shell:
	@echo ">> Entrando no container '$(PROJECT_NAME)'..."
	docker compose exec $(SERVICE) bash

# Cria o projeto Flutter dentro do container, nas plataformas informadas
create:
	docker compose exec $(SERVICE) flutter create --platforms=$(PLATFORMS) .

# Roda o flutter doctor dentro do container (diagnóstico do ambiente)
doctor:
	docker compose exec $(SERVICE) flutter doctor -v

# Mostra logs do container
logs:
	docker compose logs -f $(SERVICE)

# Lista containers do projeto
ps:
	docker compose ps

# Mostra o nome do projeto/container atual (lido do .env)
name:
	@echo "$(PROJECT_NAME)"

# Remove containers e volumes (cache do pub e do Android) deste projeto
clean:
	docker compose down -v

# ====================== Comandos de Build ======================

build-app:
	@echo ">> [$(PROJECT_NAME)] Build Linux (desktop)..."
	docker compose exec $(SERVICE) flutter build linux --release
	
	@echo ">> [$(PROJECT_NAME)] Build Android (APK)..."
	docker compose exec $(SERVICE) flutter build apk --release
	
	@echo ">> [$(PROJECT_NAME)] Build Windows..."
	@echo "!! Não é possível compilar Windows dentro de um container Linux (requer MSVC)."
	@echo "!! Use uma máquina/VM Windows ou um runner Windows no CI (ex: GitHub Actions)."

# ====================== Comandos de Qualidade de Código ======================

# Executa análise estática do código (linter + analyzer)
analyze:
	@echo ">> Executando análise estática..."
	docker compose exec $(SERVICE) dart analyze --fatal-infos

# Formata todo o código seguindo o padrão do Dart
format:
	@echo ">> Formatando código..."
	docker compose exec $(SERVICE) dart format lib test

# Aplica correções automáticas do Dart
fix:
	@echo ">> Aplicando correções automáticas..."
	docker compose exec $(SERVICE) dart fix --apply

# Executa todos os testes do projeto
test:
	@echo ">> Executando testes..."
	docker compose exec $(SERVICE) flutter test --coverage

# Gera código (freezed, riverpod, retrofit, json_serializable, etc.)
gen:
	@echo ">> Gerando código..."
	docker compose exec $(SERVICE) flutter pub run build_runner build --delete-conflicting-outputs

# ====================== Comandos Úteis ======================

# Combinação útil: formata, corrige e analisa
all: format fix analyze
	@echo ">> Formatação, correções e análise concluídas!"

# ====================== Comandos Estruturais ======================

## Cria a estrutura inicial de um novo domínio (feature).
## Uso:
##   make new-domain name="Estoque"
##   make new-domain name="Exportação de produtos"
##   make new-domain              # pergunta o nome interativamente
.PHONY: new-domain
new-domain:
	@bash scripts/new_feature.sh "$(name)"
