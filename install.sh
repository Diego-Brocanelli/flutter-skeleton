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

# Transliteração de acentos (uma vez só), reaproveitada pelos dois nomes
# abaixo. Força locale UTF-8 explicitamente — sem isso, em containers com
# locale POSIX/C, o transliterate falha silenciosamente e perde parte do
# nome (ex.: "João" vira "Jo_o" em vez de "Joao").
ASCII_NAME=$(printf '%s' "${RAW_NAME}" \
  | { command -v iconv >/dev/null 2>&1 \
      && LC_ALL=C.utf8 iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null \
      || cat; })

# CONTAINER_NAME preserva o nome digitado o máximo possível — é usado no
# container_name do compose.yml, que aceita maiúsculas/minúsculas. Só
# removemos o que o Docker realmente não aceita (espaço, símbolos). Não
# força minúsculas.
CONTAINER_NAME=$(printf '%s' "${ASCII_NAME}" \
  | tr -c 'a-zA-Z0-9_.-' '-' \
  | sed -E 's/^[-._]+//; s/[-._]+$//; s/-+/-/g')

if [ -z "${CONTAINER_NAME}" ]; then
  error "Não foi possível gerar um nome de container válido a partir de '${RAW_NAME}'."
  exit 1
fi

# IMAGE_NAME é derivado do CONTAINER_NAME, forçado em minúsculas — o
# Docker EXIGE minúsculas para nome de imagem e para o "name:" do
# Compose (diferente do container_name, que aceita mixed case).
IMAGE_NAME=$(printf '%s' "${CONTAINER_NAME}" | tr '[:upper:]' '[:lower:]')

# DART_PROJECT_NAME é o nome do pacote Dart: minúsculas, snake_case, sem
# hífen (Dart não aceita hífen em nome de pacote).
DART_PROJECT_NAME=$(printf '%s' "${ASCII_NAME}" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | sed -E 's/^_+//; s/_+$//; s/_+/_/g')
if [ -z "${DART_PROJECT_NAME}" ] || [[ "${DART_PROJECT_NAME}" =~ ^[0-9] ]]; then
  DART_PROJECT_NAME="app_${DART_PROJECT_NAME}"
fi

info "Projeto: ${RAW_NAME}"
info "Container: ${CONTAINER_NAME}"
info "Imagem Docker: ${IMAGE_NAME}"
info "Pacote Dart: ${DART_PROJECT_NAME}"

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
IMAGE_NAME=${IMAGE_NAME}
PLATFORMS=${PLATFORMS}
EOF

cat > .env.example <<EOF
APP_ENV=development
PROJECT_NAME=${CONTAINER_NAME}
IMAGE_NAME=${IMAGE_NAME}
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

rm -f lib/main.dart
rm -f test/widget_test.dart
cp -r template/lib/* lib/
mkdir -p test
cp -r template/test/* test/ 2>/dev/null || true
mkdir -p integration_test
cp -r template/integration_test/* integration_test/ 2>/dev/null || true

# Substituir o placeholder __PACKAGE_NAME__ pelo nome real do pacote
# (definido só agora, pelo `flutter create` acima) nos imports dos
# arquivos de teste. Os arquivos em lib/ não usam esse placeholder
# (usam import relativo de propósito), mas os arquivos de teste em
# test/ e integration_test/ importam código de lib/ via "package:",
# então precisam saber o nome real.
info "Ajustando nome do pacote nos imports dos testes..."
grep -rl "__PACKAGE_NAME__" test integration_test 2>/dev/null | while read -r file; do
  sed -i "s/__PACKAGE_NAME__/${DART_PROJECT_NAME}/g" "$file"
done

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
docker compose exec flutter-dev flutter pub run build_runner build --delete-conflicting-outputs

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