#!/bin/bash

# WELLARCH Installer v15.0.0
# Downloads and executes WELLARCH from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash

set -euo pipefail

# Colors
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;36m'
NC='\033[0m'

# Desativa cores em ambientes não interativos
if [ ! -t 1 ]; then
    VERDE=''
    VERMELHO=''
    AMARELO=''
    AZUL=''
    NC=''
fi

# Configuration
GITHUB_REPO="well-santos/WELLARCH"
GITHUB_BRANCH="main"
SCRIPT_NAME="wellarch.sh"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
TEMP_DIR=$(mktemp -d)
# Optional: URL to a public GPG key to import for verifying signatures
# Example: export GPG_PUBKEY_URL="https://raw.githubusercontent.com/well-santos/WELLARCH/main/pubkey.asc"
GPG_PUBKEY_URL=""

# Cleanup on exit
# shellcheck disable=SC2329 # Invoked via trap at runtime
cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT INT TERM

# Helper functions
log_info() { echo -e "${AZUL}$*${NC}" >&2; }
log_error() { echo -e "${VERMELHO}❌ $*${NC}" >&2; }
log_success() { echo -e "${VERDE}✅ $*${NC}" >&2; }
log_warn() { echo -e "${AMARELO}⚠️ $*${NC}" >&2; }

# Check internet connectivity
check_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null && ! ping -c 1 1.1.1.1 &>/dev/null; then
        log_error "Sem conexão com internet. Verifique sua conexão de rede."
        exit 1
    fi
}

# Check if curl is installed
check_curl() {
    if ! command -v curl &>/dev/null; then
        log_error "curl não está instalado. Por favor, instale com: sudo pacman -S curl"
        exit 1
    fi
}

# Download script from GitHub
download_script() {
    local script_url="${GITHUB_RAW_URL}/${SCRIPT_NAME}"
    local script_path="${TEMP_DIR}/${SCRIPT_NAME}"
    local sha_url="${script_url}.sha256"
    local sha_path="${TEMP_DIR}/${SCRIPT_NAME}.sha256"
    local CURL_OPTS=(--connect-timeout 10 --retry 3 --max-time 120 -fsSL)

    log_info "📥 Baixando WELLARCH de ${GITHUB_REPO}..."

    if ! curl "${CURL_OPTS[@]}" -o "$script_path" "$script_url"; then
        log_error "Falha ao baixar WELLARCH."
        exit 1
    fi

    if [[ ! -f "$script_path" ]]; then
        log_error "Download falhou - arquivo não encontrado."
        exit 1
    fi

    # Prefer GPG verification if signature is available, otherwise fallback to SHA256
    local sig_url="${script_url}.sig"
    local sig_path="${TEMP_DIR}/${SCRIPT_NAME}.sig"

    if command -v gpg >/dev/null 2>&1 && curl -f --connect-timeout 5 --retry 2 -sS -o "$sig_path" "$sig_url" 2>/dev/null; then
        log_info "🔐 Assinatura GPG encontrada — verificando..."
        if [[ -n "${GPG_PUBKEY_URL:-}" ]]; then
            if curl -fsSL -o "$TEMP_DIR/pubkey.asc" "$GPG_PUBKEY_URL" 2>/dev/null; then
                gpg --import "$TEMP_DIR/pubkey.asc" >/dev/null 2>&1 || true
            else
                log_warn "Não foi possível baixar a chave pública de ${GPG_PUBKEY_URL}; continuando com verificação local se possível."
            fi
        fi

        if ! gpg --verify "$sig_path" "$script_path" >/dev/null 2>&1; then
            log_error "Falha na verificação GPG do $SCRIPT_NAME"
            exit 1
        fi
        log_success "Verificação GPG OK"
    else
        # Tentar baixar checksum SHA256 opcional e verificar
        if curl -f --connect-timeout 5 --retry 2 -sS -o "$sha_path" "$sha_url" 2>/dev/null; then
            log_info "🔒 Verificando integridade via SHA256..."
            pushd "$TEMP_DIR" >/dev/null || true
            if ! sha256sum -c "${SCRIPT_NAME}.sha256" --quiet; then
                popd >/dev/null || true
                log_error "Falha na verificação SHA256 do $SCRIPT_NAME"
                exit 1
            fi
            popd >/dev/null || true
            log_success "Verificação SHA256 OK"
        else
            log_warn "Checksum SHA256 não encontrado; pulando verificação (opcional)."
        fi
    fi

    chmod +x "$script_path"
    log_success "WELLARCH baixado com sucesso!"

    echo "$script_path"
}

# Download remove script
download_remove_script() {
    local script_url="${GITHUB_RAW_URL}/wellarch-remove.sh"
    local script_path="${TEMP_DIR}/wellarch-remove.sh"

    if curl --connect-timeout 8 --retry 2 -fsSL -o "$script_path" "$script_url" 2>/dev/null; then
        chmod +x "$script_path"
        # Copy to user's directory for later use
        mkdir -p "$HOME/.local/bin"
        if cp "$script_path" "$HOME/.local/bin/wellarch-remove.sh" 2>/dev/null; then
            log_success "wellarch-remove.sh instalado em ~/.local/bin"
        else
            log_warn "Não foi possível copiar wellarch-remove.sh para ~/.local/bin"
        fi
        return 0
    fi
    return 1
}

# Show banner
show_banner() {
    echo -e "${AZUL}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║            WELLARCH Installer v15.0                          ║
║   Automação e Otimização para Arch Linux                     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Main
main() {
    show_banner
    
    # Validations
    check_curl
    check_internet

    # Garantir TTY para menus interativos quando rodado via curl | bash
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
        log_error "Ambiente sem TTY detectado. Abra um terminal interativo e rode novamente."
        exit 1
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "Não execute como root. Este script pedirá a senha quando necessário."
        exit 1
    fi
    
    # Download the main script
    script_path=$(download_script)
    
    # Try to download remove script
    log_info "📦 Preparando ferramentas de desinstalação..."
    if download_remove_script; then
        log_success "Ferramentas de desinstalação disponíveis em ~/.local/bin/wellarch-remove.sh"
    else
        log_warn "Não foi possível baixar script de desinstalação (você pode clonar o repo para usar)"
    fi
    
    echo ""
    log_info "🚀 Iniciando WELLARCH..."
    echo ""
    
    # Execute with all passed arguments
    # Fix: Reconectar stdin ao TTY para permitir interatividade quando rodado via pipe (curl | bash)
    if [ ! -t 0 ] && [ -e /dev/tty ]; then
        bash "$script_path" "$@" < /dev/tty
    else
        bash "$script_path" "$@"
    fi

    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "WELLARCH finalizado com sucesso!"
    else
        log_error "WELLARCH terminou com erros (código: $exit_code)"
    fi
    
    exit $exit_code
}

# Run main with all arguments
main "$@"
