#!/usr/bin/env bash
#
# Bootstrap para Flutter Skeleton

set -euo pipefail

# Configuração
REPO_URL="https://github.com/Diego-Brocanelli/flutter-skeleton.git"

# Helpers
info() { printf "\033[1;34m>>\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$1"; }
error() { printf "\033[1;31mxx\033[0m %s\n" "$1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { error "Comando '$1' não encontrado."; exit 1; }
}

require_cmd git
require_cmd docker
require_cmd make

echo "=========================================="
echo " Flutter Skeleton - Bootstrap"
echo "=========================================="

# Nome do projeto
read -rp "Nome do projeto: " RAW_NAME
if [ -z "${RAW_NAME}" ]; then error "Nome obrigatório."; exit 1; fi
if [ -d "${RAW_NAME}" ]; then error "Diretório já existe."; exit 1; fi

CONTAINER_NAME=$(echo "${RAW_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_.-' '-' | sed -E 's/^[-.]+//; s/[-.]+$//; s/-+/-/g')
DART_PROJECT_NAME=$(echo "${RAW_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | sed -E 's/^_+//; s/_+$//; s/_+/_/g')

info "Projeto: ${RAW_NAME}"
info "Container: ${CONTAINER_NAME}"
info "Pacote: ${DART_PROJECT_NAME}"

# Clonar
info "Clonando template..."
git clone --quiet "${REPO_URL}" "${RAW_NAME}"
cd "${RAW_NAME}"

# Plataformas
echo ""
echo "Plataformas (separadas por espaço):"
echo "1)android 2)ios 3)web 4)linux 5)windows 6)macos"
read -rp "Opções: " OPTS

PLATFORMS=""
for opt in ${OPTS}; do
  case "${opt}" in
    1) PLATFORMS="${PLATFORMS}android," ;;
    2) PLATFORMS="${PLATFORMS}ios," ;;
    3) PLATFORMS="${PLATFORMS}web," ;;
    4) PLATFORMS="${PLATFORMS}linux," ;;
    5) PLATFORMS="${PLATFORMS}windows," ;;
    6) PLATFORMS="${PLATFORMS}macos," ;;
  esac
done
PLATFORMS="${PLATFORMS%,}"
[ -z "${PLATFORMS}" ] && PLATFORMS="android,linux"

# .env
cat > .env <<EOF
APP_ENV=development
PROJECT_NAME=${CONTAINER_NAME}
PLATFORMS=${PLATFORMS}
EOF

cat > .env.example <<EOF
APP_ENV=development
PROJECT_NAME=${CONTAINER_NAME}
PLATFORMS=${PLATFORMS}
EOF

# Docker
info "Buildando imagem Docker..."
make build

info "Subindo container..."
make up
sleep 4

# Flutter create
info "Executando flutter create..."
docker compose exec flutter-dev flutter create --platforms="${PLATFORMS}" --project-name "${DART_PROJECT_NAME}" .

# Aplicar template
info "Aplicando estrutura do template (com src/)..."

rm -rf lib/test lib/main.dart
cp -r template/lib/* lib/
cp -r template/test/* test/ 2>/dev/null || true
cp -r template/integration_test/* integration_test/ 2>/dev/null || true

# Dependências
info "Instalando dependências..."
docker compose exec flutter-dev flutter pub add \
  flutter_riverpod riverpod riverpod_annotation \
  go_router \
  flutter_native_splash flutter_launcher_icons

docker compose exec flutter-dev flutter pub add --dev \
  build_runner riverpod_generator mocktail very_good_analysis

docker compose exec flutter-dev flutter pub add 'dev:integration_test:{"sdk":"flutter"}'

# Build runner
info "Gerando código..."
docker compose exec flutter-dev flutter pub run build_runner build --delete-conflicting-outputs || true

# Finalização
info "Limpando arquivos temporários..."
rm -rf template

info "Inicializando repositório git..."
rm -rf .git
git init --quiet -b main

echo ""
info "✅ Projeto '${RAW_NAME}' criado com sucesso!"
echo "cd ${RAW_NAME} && make shell"
echo ""

make shell