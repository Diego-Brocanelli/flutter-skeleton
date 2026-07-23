#!/usr/bin/env bash
#
# Bootstrap para projetos Flutter baseados neste template Docker.
#
# Uso recomendado:
# bash <(curl -fsSL https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/main/install.sh)

set -euo pipefail

# ---- Configuração ----------------------------------------------------------
# v1
# REPO_URL="https://github.com/Diego-Brocanelli/flutter-skeleton.git"
# v2
REPO_BRANCH=v2 bash <(curl -fsSL https://raw.githubusercontent.com/Diego-Brocanelli/flutter-skeleton/v2/install.sh)

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

info "DEBUG: Diretório atual = $(pwd)"

# Copiar estrutura do template (se existir)
if [ -d "template/lib" ]; then
  info "Copiando estrutura do template..."
  cp -r template/lib/* lib/ 2>/dev/null || true
  info "Estrutura do template aplicada com sucesso."
else
  warn "Pasta 'template/lib' não encontrada."
fi

# Copiar testes de unidade/widget do template (substitui o
# test/widget_test.dart padrão gerado pelo `flutter create`)
if [ -d "template/test" ]; then
  info "Copiando testes (unit/widget) do template..."
  rm -f test/widget_test.dart
  cp -r template/test/* test/ 2>/dev/null || true
  info "Testes aplicados com sucesso."
else
  warn "Pasta 'template/test' não encontrada."
fi

# Copiar testes de integração do template (o `flutter create` não gera
# a pasta integration_test/ por padrão)
if [ -d "template/integration_test" ]; then
  info "Copiando testes de integração do template..."
  mkdir -p integration_test
  cp -r template/integration_test/* integration_test/ 2>/dev/null || true
  info "Testes de integração aplicados com sucesso."
else
  warn "Pasta 'template/integration_test' não encontrada."
fi

rm -rf template

# Substituir o placeholder __PACKAGE_NAME__ pelo nome real do pacote
# (definido só agora, pelo `flutter create` acima) nos imports dos
# arquivos de teste. Os arquivos em lib/ não usam esse placeholder
# (usam import relativo de propósito, para não depender do nome do
# pacote), mas os arquivos de teste em test/ e integration_test/ importam
# código de lib/ via "package:", então precisam saber o nome real.
info "Ajustando nome do pacote nos imports dos testes..."
grep -rl "__PACKAGE_NAME__" test integration_test 2>/dev/null | while read -r file; do
  sed -i "s/__PACKAGE_NAME__/${DART_PROJECT_NAME}/g" "$file"
done

# ====================== COMANDOS DENTRO DO CONTAINER ======================
info "Instalando dependências e configurando o projeto..."

# Dependências principais
docker compose exec flutter-dev flutter pub add \
  flutter_riverpod riverpod riverpod_annotation \
  go_router \
  dio retrofit \
  json_annotation \
  logger \
  flutter_native_splash flutter_launcher_icons

# Dependências de desenvolvimento
docker compose exec flutter-dev flutter pub add --dev \
  build_runner \
  riverpod_generator \
  retrofit_generator \
  freezed \
  json_serializable \
  mocktail \
  very_good_analysis

# integration_test é uma dependência de SDK (faz parte do próprio Flutter,
# não do pub.dev), por isso precisa dessa sintaxe especial em vez de entrar
# na lista acima. flutter_test já vem incluído por padrão pelo `flutter
# create`, então não precisa ser adicionado de novo aqui.
info "Adicionando dependência de SDK: integration_test..."
docker compose exec flutter-dev flutter pub add 'dev:integration_test:{"sdk":"flutter"}'

# Configurações visuais (comentado temporariamente até configurar pubspec)
# info "Configurando Native Splash e Launcher Icons..."
# docker compose exec flutter-dev flutter pub run flutter_native_splash:create
# docker compose exec flutter-dev flutter pub run flutter_launcher_icons

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