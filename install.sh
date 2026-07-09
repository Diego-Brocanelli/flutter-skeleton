#!/usr/bin/env bash
#
# Bootstrap para projetos Flutter baseados neste template Docker.
#
# Uso recomendado:
# bash <(curl -fsSL https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/main/install.sh)

set -euo pipefail

# ---- Configuração ----------------------------------------------------------
REPO_URL="https://github.com/Diego-Brocanelli/flutter-skeleton.git"

# ---- Helpers ----------------------------------------------------------------
info() { printf "\033[1;34m>>\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m!!\033[0m %s\n" "$1"; }
error() { printf "\033[1;31mxx\033[0m %s\n" "$1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { error "Comando '$1' não encontrado. Instale-o antes de continuar."; exit 1; }
}

require_cmd git
require_cmd docker
require_cmd make

echo "=========================================="
echo " Flutter Docker Template - Bootstrap"
echo "=========================================="
echo ""

# ---- Nome do projeto ---------------------------------------------------------
read -rp "Nome do projeto: " RAW_NAME
if [ -z "${RAW_NAME}" ]; then
  error "Nome do projeto é obrigatório."
  exit 1
fi
if [ -d "${RAW_NAME}" ]; then
  error "Já existe um diretório chamado '${RAW_NAME}' aqui."
  exit 1
fi

# Normalização dos nomes
CONTAINER_NAME=$(echo "${RAW_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_.-' '-' | sed -E 's/^[-.]+//; s/[-.]+$//; s/-+/-/g')
DART_PROJECT_NAME=$(echo "${RAW_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | sed -E 's/^_+//; s/_+$//; s/_+/_/g')

if [ -z "${DART_PROJECT_NAME}" ] || [[ "${DART_PROJECT_NAME}" =~ ^[0-9] ]]; then
  DART_PROJECT_NAME="app_${DART_PROJECT_NAME}"
fi

info "Diretório: ${RAW_NAME}"
info "Container/Imagem: ${CONTAINER_NAME}"
info "Pacote Flutter: ${DART_PROJECT_NAME}"

# ---- Clonar o template -------------------------------------------------------
info "Clonando template..."
git clone --quiet "${REPO_URL}" "${RAW_NAME}"
cd "${RAW_NAME}"

# ---- Escolha de plataformas --------------------------------------------------
echo ""
echo "Quais plataformas o projeto deve suportar? (separadas por espaço)"
echo " 1) android   2) ios   3) web   4) linux   5) windows   6) macos"
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
    *) warn "Opção inválida ignorada: ${opt}" ;;
  esac
done
PLATFORMS="${PLATFORMS%,}"
if [ -z "${PLATFORMS}" ]; then
  PLATFORMS="android,linux"
fi

info "Plataformas selecionadas: ${PLATFORMS}"

# ---- Persistir configuração -------------------------------------------------
cat > .env <<EOF
PROJECT_NAME=${CONTAINER_NAME}
PLATFORMS=${PLATFORMS}
EOF

cat > .env.example <<EOF
PROJECT_NAME=${CONTAINER_NAME}
PLATFORMS=${PLATFORMS}
EOF

# ---- Build e subida do container --------------------------------------------
info "Buildando imagem Docker..."
make build

info "Subindo container..."
make up

sleep 3

# ---- Criação do projeto Flutter ---------------------------------------------
info "Criando projeto Flutter..."
docker compose exec flutter-dev flutter create --platforms="${PLATFORMS}" --project-name "${DART_PROJECT_NAME}" .

# ---- Aplicar estrutura avançada e dependências ---------------------------
info "Aplicando estrutura avançada e dependências modernas..."

echo "DEBUG: Diretório atual = $(pwd)"

cd "${RAW_NAME}" || { error "Não foi possível entrar no diretório do projeto"; exit 1; }

echo "DEBUG: Diretório atual = $(pwd)"

# Copiar template (se existir)
if [ -d "template/lib" ]; then
  cp -r template/lib/* lib/ 2>/dev/null || true
  rm -rf template
fi

# ====================== COMANDOS DENTRO DO CONTAINER ======================

info "Instalando dependências e gerando código dentro do container..."

docker compose exec flutter-dev flutter pub add \
  flutter_riverpod riverpod_annotation \
  go_router \
  dio retrofit \
  freezed json_annotation \
  logger \
  flutter_native_splash flutter_launcher_icons

docker compose exec flutter-dev flutter pub add --dev \
  build_runner \
  riverpod_generator \
  retrofit_generator \
  freezed \
  json_serializable \
  mocktail \
  very_good_analysis

# Configurações visuais
docker compose exec flutter-dev flutter pub run flutter_native_splash:create --force
docker compose exec flutter-dev flutter pub run flutter_launcher_icons

# Geração de código
info "Gerando código (Freezed, Riverpod, etc.)..."
docker compose exec flutter-dev flutter pub run build_runner build --delete-conflicting-outputs

# ---- Finalização ------------------------------------------------------------
info "Removendo histórico git do template..."
rm -rf .git
git init --quiet -b main

echo ""
info "✅ Projeto '${RAW_NAME}' criado com sucesso!"
info "Container: ${CONTAINER_NAME} | Pacote: ${DART_PROJECT_NAME}"
info "Stack: Riverpod + go_router + Freezed"
echo ""
info "Para começar a desenvolver:"
echo "   cd ${RAW_NAME}"
echo "   make shell"
echo ""
make shell
