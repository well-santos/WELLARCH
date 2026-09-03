#!/bin/bash
# ==============================================================================
# WELLARCH Installer v15.1.0
# Downloads and executes WELLARCH from GitHub
# Usage: curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
# ==============================================================================

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

# Helper functions
log_info() { echo -e "${AZUL}ℹ️  $*${NC}" >&2; }
log_error() { echo -e "${VERMELHO}❌ $*${NC}" >&2; }
log_success() { echo -e "${VERDE}✅ $*${NC}" >&2; }
log_warn() { echo -e "${AMARELO}⚠️  $*${NC}" >&2; }

# Configuration
GITHUB_REPO="well-santos/WELLARCH"
GITHUB_COMMIT="${WELLARCH_COMMIT:-8270e514a7a6acf74b90215abd8027c2e2538e01}"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_COMMIT}"
INSTALL_DIR="${WELLARCH_INSTALL_DIR:-$HOME/.local/wellarch}"

# Cleanup on exit
cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
TEMP_DIR=$(mktemp -d)
trap cleanup EXIT INT TERM

# Show banner
show_banner() {
    echo -e "${AZUL}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║            WELLARCH Installer v15.1.0                         ║
║   Automação e Otimização para Arch Linux                     ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if curl is installed
check_curl() {
    if ! command -v curl &>/dev/null; then
        log_error "curl não está instalado. Instale com: sudo pacman -S curl"
        exit 1
    fi
}

# Check if git is installed
check_git() {
    if ! command -v git &>/dev/null; then
        log_warn "git não encontrado. Usando fallback de download..."
        return 1
    fi
    return 0
}

# Download all files using curl
download_with_curl() {
    local output_dir="$1"
    mkdir -p "$output_dir/lib"
    
    log_info "📥 Baixando WELLARCH de ${GITHUB_REPO}..."
    
    # Download main script
    if ! curl -fsSL --max-time 30 \
        -o "$output_dir/wellarch.sh" \
        "${GITHUB_RAW_URL}/wellarch.sh"; then
        log_error "Falha ao baixar wellarch.sh"
        return 1
    fi
    chmod +x "$output_dir/wellarch.sh"
    
    # Download all library files
    local libs=(
        "common.sh"
        "menu.sh"
        "system.sh"
        "steps.sh"
        "aur.sh"
        "mirrors.sh"
        "flatpak.sh"
        "packages.sh"
        "dns.sh"
        "system_setup.sh"
        "linuxtoys.sh"
    )
    
    log_info "📦 Baixando bibliotecas..."
    for lib in "${libs[@]}"; do
        if ! curl -fsSL --max-time 20 \
            -o "$output_dir/lib/$lib" \
            "${GITHUB_RAW_URL}/lib/$lib" 2>/dev/null; then
            log_error "Não foi possível baixar lib/$lib"
            return 1
        fi
    done
    chmod +x "$output_dir/lib"/*.sh 2>/dev/null || true
    
    log_success "Arquivos baixados para: $output_dir"
    return 0
}

# Clone with git (faster and more reliable)
download_with_git() {
    local output_dir="$1"
    
    log_info "📥 Clonando WELLARCH via git..."
    
    mkdir -p "$(dirname "$output_dir")"
    
    if git init -q "$output_dir" && \
        git -C "$output_dir" remote add origin "https://github.com/${GITHUB_REPO}.git" && \
        git -C "$output_dir" fetch -q --depth 1 origin "$GITHUB_COMMIT" && \
        git -C "$output_dir" checkout -q --detach FETCH_HEAD; then
        log_success "Repositório clonado com sucesso"
        chmod +x "$output_dir"/wellarch.sh
        chmod +x "$output_dir"/lib/*.sh 2>/dev/null || true
        return 0
    fi
    
    return 1
}

# Main
main() {
    show_banner
    
    # Validations
    check_curl
    
    # Garantir TTY para menus interativos
    if [ ! -t 0 ] && [ ! -e /dev/tty ]; then
        log_error "Ambiente sem TTY. Abra um terminal interativo."
        exit 1
    fi
    
    # Check if already installed
    if [[ -f "$INSTALL_DIR/wellarch.sh" && -d "$INSTALL_DIR/lib" ]]; then
        log_info "WELLARCH já existe em: $INSTALL_DIR"
        read -p "Atualizar? (s/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            log_info "Usando instalação existente..."
            SKIP_DOWNLOAD=true
        fi
    fi
    
    # Download if needed
    if [[ "${SKIP_DOWNLOAD:-false}" != true ]]; then
        # Try git first (faster), fall back to curl
        if check_git; then
            if ! download_with_git "$INSTALL_DIR"; then
                log_warn "Falha ao clonar via git, tentando curl..."
                download_with_curl "$INSTALL_DIR" || exit 1
            fi
        else
            download_with_curl "$INSTALL_DIR" || exit 1
        fi
    fi
    
    # Validate structure
    if [[ ! -f "$INSTALL_DIR/wellarch.sh" ]]; then
        log_error "wellarch.sh não encontrado em $INSTALL_DIR"
        exit 1
    fi
    
    if [[ ! -d "$INSTALL_DIR/lib" ]] || [[ ! -f "$INSTALL_DIR/lib/common.sh" ]]; then
        log_error "pasta lib/ ou lib/common.sh não encontrada em $INSTALL_DIR"
        exit 1
    fi

    local required_lib
    for required_lib in common.sh menu.sh system.sh steps.sh aur.sh mirrors.sh flatpak.sh packages.sh dns.sh system_setup.sh linuxtoys.sh; do
        if [[ ! -s "$INSTALL_DIR/lib/$required_lib" ]]; then
            log_error "Biblioteca obrigatória ausente ou vazia: lib/$required_lib"
            exit 1
        fi
    done
    
    log_success "Estrutura validada"
    echo ""
    
    # Prepare arguments
    local args=("$@")
    if [[ ${#args[@]} -eq 0 ]]; then
        log_info "💡 Dica: use 'wellarch --help' para ver opções"
        log_info "🚀 Executando WELLARCH v15.1.0 em modo interativo..."
    else
        log_info "🚀 Executando WELLARCH v15.1.0..."
    fi
    echo ""
    
    # Execute with correct lib directory
    export WELLARCH_LIB_DIR="$INSTALL_DIR/lib"
    cd "$INSTALL_DIR"
    
    # Reconnect stdin to /dev/tty if available (for interactive menus via pipe)
    if [ ! -t 0 ] && [ -e /dev/tty ]; then
        bash wellarch.sh "${args[@]}" < /dev/tty
    else
        bash wellarch.sh "${args[@]}"
    fi
    
    exit_code=$?
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "WELLARCH finalizado com sucesso!"
        log_info "📍 Instalação em: $INSTALL_DIR"
        log_info "💡 Próximas execuções: WELLARCH_LIB_DIR=$INSTALL_DIR/lib bash $INSTALL_DIR/wellarch.sh"
    else
        log_error "WELLARCH terminou com erros (código: $exit_code)"
    fi
    
    exit $exit_code
}

# Run main with all arguments
main "$@"
