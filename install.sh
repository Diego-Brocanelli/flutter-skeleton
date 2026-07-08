#!/usr/bin/env bash
#
# Bootstrap para projetos Flutter baseados neste template Docker.
#
# Uso recomendado (preserva a interatividade do terminal):
#   bash <(curl -fsSL https://raw.githubusercontent.com/USUARIO/REPO/main/install.sh)
#   bash <(wget -qO- https://raw.githubusercontent.com/USUARIO/REPO/main/install.sh)
#
# Evite "curl ... | bash" ou "wget ... | bash": nesse modo o stdin é consumido
# pelo próprio pipe e os prompts abaixo (read) não funcionam.

set -euo pipefail

# ---- Configuração ----------------------------------------------------------
REPO_URL="https://github.com/USUARIO/REPO.git"

# ---- Helpers ----------------------------------------------------------------
info()  { printf "\033[1;34m>>\033[0m %s\n" "$1"; }
warn()  { printf "\033[1;33m!!\033[0m %s\n" "$1"; }
error() { printf "\033[1;31mxx\033[0m %s\n" "$1" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { error "Comando '$1' não encontrado. Instale-o antes de continuar."; exit 1; }
}

require_cmd git
require_cmd docker

echo "=========================================="
echo "  Flutter Docker Template - Bootstrap"
echo "=========================================="
echo ""

# ---- Nome do projeto ---------------------------------------------------------
read -rp "Nome do projeto: " RAW_NAME
if [ -z "${RAW_NAME}" ]; then
  error "Nome do projeto é obrigatório."
  exit 1
fi

if [ -d "${RAW_NAME}" ]; then
  error "Já existe um diretório chamado '${RAW_NAME}' aqui. Escolha outro nome ou remova/renomeie o existente."
  exit 1
fi

# Nome do container/imagem Docker: mantém o nome digitado pelo usuário,
# normalizado para o formato aceito pelo Docker ([a-zA-Z0-9][a-zA-Z0-9_.-]+).
CONTAINER_NAME=$(echo "${RAW_NAME}" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9_.-' '-' \
  | sed -E 's/^[-.]+//; s/[-.]+$//; s/-+/-/g')

if [ -z "${CONTAINER_NAME}" ]; then
  error "Nome de projeto inválido: não sobrou nenhum caractere válido."
  exit 1
fi

if docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  error "Já existe um container/imagem Docker chamado '${CONTAINER_NAME}'. Escolha outro nome, ou remova-o com 'docker rm -f ${CONTAINER_NAME}'."
  exit 1
fi

# Nome de pacote Dart válido: minúsculo, snake_case, sem começar com número.
# Usado apenas para o "flutter create --project-name", não afeta o container.
DART_PROJECT_NAME=$(echo "${RAW_NAME}" \
  | tr '[:upper:]' '[:lower:]' \
  | tr -c 'a-z0-9' '_' \
  | sed -E 's/^_+//; s/_+$//; s/_+/_/g')

if [ -z "${DART_PROJECT_NAME}" ] || [[ "${DART_PROJECT_NAME}" =~ ^[0-9] ]]; then
  DART_PROJECT_NAME="app_${DART_PROJECT_NAME}"
fi

info "Diretório: ${RAW_NAME}"
info "Nome do container/imagem: ${CONTAINER_NAME}"
info "Nome do pacote Flutter: ${DART_PROJECT_NAME}"

# ---- Clonar o template -------------------------------------------------------
info "Clonando template..."
git clone --quiet "${REPO_URL}" "${RAW_NAME}"
cd "${RAW_NAME}"

# Reinicia o histórico git para o novo projeto
rm -rf .git
git init --quiet -b main

# ---- Escolha de plataformas --------------------------------------------------
echo ""
echo "Quais plataformas o projeto deve suportar?"
echo "Selecione uma ou mais opções separadas por espaço (ex: 1 3 4):"
echo "  1) android"
echo "  2) ios"
echo "  3) web"
echo "  4) linux (desktop)"
echo "  5) windows (desktop)"
echo "  6) macos (desktop)"
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
  warn "Nenhuma plataforma válida selecionada. Usando 'android,linux' como padrão."
  PLATFORMS="android,linux"
fi

info "Plataformas selecionadas: ${PLATFORMS}"

# Nota: builds de ios/macos/windows exigem, respectivamente, um host macOS ou
# Windows (ou runners de CI apropriados) — este container Linux não compila
# para essas plataformas, apenas gera a estrutura inicial do projeto.

# ---- Persistir configuração em .env ------------------------------------------
# PROJECT_NAME é lido pelo docker-compose.yml para nomear o container/imagem/
# volumes deste projeto (isso é o que evita conflito entre projetos diferentes
# rodando na mesma máquina).
cat > .env <<EOF
PROJECT_NAME=${CONTAINER_NAME}
PLATFORMS=${PLATFORMS}
EOF

# ---- Build e subida do container ---------------------------------------------
info "Buildando a imagem Docker (pode demorar na primeira vez)..."
make build

info "Subindo o container..."
make up

info "Aguardando o container inicializar..."
sleep 2

# ---- Criação do projeto Flutter ----------------------------------------------
info "Criando o projeto Flutter (flutter create --platforms=${PLATFORMS})..."
docker compose exec flutter-dev flutter create --platforms="${PLATFORMS}" --project-name "${DART_PROJECT_NAME}" .

echo ""
info "Projeto '${RAW_NAME}' criado com sucesso em ./${RAW_NAME}"
info "Container: ${CONTAINER_NAME}  |  Pacote Flutter: ${DART_PROJECT_NAME}"
info "Abrindo o shell do container..."
echo ""

make shell