#!/bin/bash

# WELLARCH Installer v14.0
# Downloads and executes WELLARCH from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash

set -euo pipefail

# Colors
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;36m'
NC='\033[0m'

# Configuration
GITHUB_REPO="well-santos/WELLARCH"
GITHUB_BRANCH="main"
SCRIPT_NAME="wellarch.sh"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"
TEMP_DIR=$(mktemp -d)

# Cleanup on exit
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
    
    log_info "📥 Baixando WELLARCH de ${GITHUB_REPO}..."
    
    if ! curl -fsSL -o "$script_path" "$script_url"; then
        log_error "Falha ao baixar WELLARCH."
        exit 1
    fi
    
    if [[ ! -f "$script_path" ]]; then
        log_error "Download falhou - arquivo não encontrado."
        exit 1
    fi
    
    chmod +x "$script_path"
    log_success "WELLARCH baixado com sucesso!"
    
    echo "$script_path"
}

# Download remove script
download_remove_script() {
    local script_url="${GITHUB_RAW_URL}/wellarch-remove.sh"
    local script_path="${TEMP_DIR}/wellarch-remove.sh"
    
    if curl -fsSL -o "$script_path" "$script_url" 2>/dev/null; then
        chmod +x "$script_path"
        # Copy to user's directory for later use
        cp "$script_path" "$HOME/.local/bin/wellarch-remove.sh" 2>/dev/null || true
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
║            WELLARCH Installer v14.0                          ║
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
    bash "$script_path" "$@"
    exit_code=$?
    
    exit $exit_code
}

# Run main with all arguments
main "$@"
