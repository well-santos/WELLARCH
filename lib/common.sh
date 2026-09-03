#!/bin/bash
# ==============================================================================
# WELLARCH Common Library v15.1.0
# Shared functions, colors, and constants for all WELLARCH scripts
# ==============================================================================

# shellcheck disable=SC2034  # Variables are used by sourcing scripts

# Prevent multiple sourcing
[[ -n "${_WELLARCH_COMMON_LOADED:-}" ]] && return 0
readonly _WELLARCH_COMMON_LOADED=1

# ==============================================================================
# VERSION AND CONSTANTS
# ==============================================================================
readonly WELLARCH_VERSION="15.1.0"

# External URLs (exported for use by sourcing scripts)
readonly CHAOTIC_KEY="3056513887B78AEB"
readonly CHAOTIC_KEYSERVER="keyserver.ubuntu.com"
readonly CHAOTIC_KEYRING_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
readonly CHAOTIC_MIRRORLIST_URL="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
readonly LINUXTOYS_URL="https://linux.toys/install.sh"
readonly OHMYZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/tools/install.sh"
readonly OHMYZSH_SHA256="5b16896b831243ebd2f409ecd99c3d231385cc706fbc564625057929ebee5e6e"
readonly LINUXTOYS_SHA256="9ead4c13e02346481ec4ed3734b607e4a5c41f51223293cc9f6523a7b7ab963d"

# DNS Providers (associative array for use by sourcing scripts)
declare -A DNS_PROVIDERS=(
    ["cloudflare"]="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
    ["quad9"]="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
    ["google"]="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
    ["adguard"]="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
)

# Default configuration paths
readonly WELLARCH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wellarch"
readonly WELLARCH_CONFIG_FILE="${WELLARCH_CONFIG_DIR}/config"
readonly WELLARCH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wellarch"
readonly WELLARCH_LOG_FILE="${WELLARCH_CACHE_DIR}/wellarch.log"
readonly WELLARCH_MANIFEST_FILE="${WELLARCH_CONFIG_DIR}/installed-manifest"

# ==============================================================================
# COLOR DEFINITIONS
# ==============================================================================
setup_colors() {
    if [[ -t 1 ]]; then
        readonly GREEN='\033[0;32m'
        readonly RED='\033[0;31m'
        readonly YELLOW='\033[1;33m'
        readonly CYAN='\033[0;36m'
        readonly PURPLE='\033[0;35m'
        readonly BOLD='\033[1m'
        readonly NC='\033[0m'
        # Portuguese aliases for compatibility
        readonly VERDE="$GREEN"
        readonly VERMELHO="$RED"
        readonly AMARELO="$YELLOW"
        readonly AZUL="$CYAN"
        readonly ROXO="$PURPLE"
    else
        readonly GREEN='' RED='' YELLOW='' CYAN='' PURPLE='' BOLD='' NC=''
        readonly VERDE='' VERMELHO='' AMARELO='' AZUL='' ROXO=''
    fi
}

# Initialize colors
setup_colors

# ==============================================================================
# BASH VERSION CHECK
# ==============================================================================
check_bash_version() {
    local required_major="${1:-4}"
    local required_minor="${2:-0}"
    
    if ((BASH_VERSINFO[0] < required_major)) || \
       ((BASH_VERSINFO[0] == required_major && BASH_VERSINFO[1] < required_minor)); then
        echo -e "${RED}❌ ERRO: Requer Bash ${required_major}.${required_minor} ou superior.${NC}" >&2
        echo -e "${RED}   Versão atual: ${BASH_VERSION}${NC}" >&2
        exit 1
    fi
}

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================
LOG_LEVEL_NUM=2  # Default: info

set_log_level() {
    case "${1,,}" in
        debug)   LOG_LEVEL_NUM=3 ;;
        info)    LOG_LEVEL_NUM=2 ;;
        warn|warning) LOG_LEVEL_NUM=1 ;;
        error)   LOG_LEVEL_NUM=0 ;;
        *)
            echo -e "${RED}❌ LOG_LEVEL inválido: $1 (use debug|info|warn|error)${NC}" >&2
            return 1
            ;;
    esac
}

log_to_file() {
    local log_file="${WELLARCH_LOG_FILE}"
    mkdir -p "$(dirname "$log_file")"
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $*" >> "$log_file"
}

log_debug() {
    [[ "$LOG_LEVEL_NUM" -ge 3 ]] && echo -e "${CYAN}[DEBUG]${NC} $*"
    log_to_file "[DEBUG] $*"
}

log_info() {
    [[ "$LOG_LEVEL_NUM" -ge 2 ]] && echo -e "${CYAN}$*${NC}"
    log_to_file "[INFO] $*"
}

log_warn() {
    [[ "$LOG_LEVEL_NUM" -ge 1 ]] && echo -e "${YELLOW}⚠️ $*${NC}"
    log_to_file "[WARN] $*"
}

log_error() {
    [[ "$LOG_LEVEL_NUM" -ge 0 ]] && echo -e "${RED}❌ $*${NC}" >&2
    log_to_file "[ERROR] $*"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
    log_to_file "[SUCCESS] $*"
}

record_installed_item() {
    local type="$1"
    local name="$2"
    mkdir -p "$(dirname "$WELLARCH_MANIFEST_FILE")"
    grep -Fqx -- "$type|$name" "$WELLARCH_MANIFEST_FILE" 2>/dev/null || \
        printf '%s|%s\n' "$type" "$name" >> "$WELLARCH_MANIFEST_FILE"
}

run_quiet_with_progress() {
    local label="$1"
    shift
    local pid
    local key
    local frame=0

    "$@" >>"$WELLARCH_LOG_FILE" 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        if [[ "${VERBOSE:-false}" != true && -t 0 && -t 1 ]]; then
            if read -r -t 0.1 -n 1 key; then
                if [[ "$key" =~ [vV] ]]; then
                    VERBOSE=true
                    printf '\nDetalhes ativados. Log: %s\n' "$WELLARCH_LOG_FILE"
                fi
            fi
        fi

        if [[ "${VERBOSE:-false}" == true ]]; then
            tail -n 1 "$WELLARCH_LOG_FILE" 2>/dev/null || true
        else
            frame=$(( (frame + 1) % 4 ))
            case "$frame" in
                1) printf '\r%s.  ' "$label" ;;
                2) printf '\r%s.. ' "$label" ;;
                3) printf '\r%s... ' "$label" ;;
                *) printf '\r%s    ' "$label" ;;
            esac
        fi
        sleep 1
    done
    wait "$pid"
    printf '\r%-80s\r' ""
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Check if a command is installed
is_installed() {
    command -v "$1" &>/dev/null
}

# Check if a package is installed via pacman
is_pkg_installed() {
    pacman -Qi "$1" >/dev/null 2>&1
}

# Get official repository for a package
get_official_repo() {
    local pkg="$1"
    local repo
    for repo in core extra community multilib; do
        if pacman -Si "${repo}/$pkg" >/dev/null 2>&1; then
            echo "$repo"
            return 0
        fi
    done
    return 1
}

# Check if package is in Chaotic AUR
is_chaotic_pkg() {
    pacman -Si "chaotic-aur/$1" >/dev/null 2>&1
}

# Stop script with error message
die() {
    log_error "ERRO CRÍTICO: $1"
    log_error "Script interrompido."
    exit "${2:-1}"
}

# Alias for Portuguese compatibility
parar_com_erro() {
    die "$1" "${2:-1}"
}

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

# Prompt for choice with validation
prompt_choice() {
    local prompt="$1"
    local default="$2"
    local valid_options="${3:-}"  # Optional: regex pattern like "a|b|c"
    local assume_yes="${ASSUME_YES:-false}"
    local choice
    
    if [[ "$assume_yes" == true ]]; then
        echo "$default"
        return 0
    fi
    
    while true; do
        read -r -p "$prompt [$default]: " choice
        choice="${choice:-$default}"
        
        # If no validation pattern, accept anything
        if [[ -z "$valid_options" ]]; then
            echo "$choice"
            return 0
        fi
        
        # Validate against pattern
        if [[ "${choice,,}" =~ ^($valid_options)$ ]]; then
            echo "$choice"
            return 0
        fi
        
        echo -e "${YELLOW}Opção inválida. Escolha entre: ${valid_options/|/, }${NC}" >&2
    done
}

# Prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local assume_yes="${ASSUME_YES:-false}"
    
    if [[ "$assume_yes" == true ]]; then
        echo "y"
        return 0
    fi
    
    local choice
    read -r -p "$prompt [$default]: " choice
    choice="${choice:-$default}"
    
    [[ "${choice,,}" =~ ^(y|yes|s|sim)$ ]] && echo "y" || echo "n"
}

# ==============================================================================
# ==============================================================================
# SYSTEM CHECKS
# ==============================================================================

# Check internet connectivity
check_internet() {
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null && ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        die "Sem conexão com internet. Verifique sua conexão de rede."
    fi
}

# Check available disk space
check_disk_space() {
    local path="${1:-$HOME}"
    local required_kb="${2:-$((3 * 1024 * 1024))}"  # Default: 3GB in KB
    local available
    
    available=$(df "$path" 2>/dev/null | tail -1 | awk '{print $4}') || available=0
    
    if [[ -z "$available" || "$available" -lt "$required_kb" ]]; then
        local available_human
        available_human=$(numfmt --to=iec-i --suffix=B $((available * 1024)) 2>/dev/null || echo "${available}KB")
        log_warn "Apenas ${available_human} disponíveis. Recomendado: 3GB ou mais."
        return 1
    fi
    return 0
}

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        die "Não execute como root. O script pedirá a senha quando necessário."
    fi
}

# Check if running on Arch Linux
check_arch_linux() {
    if ! grep -qi "arch" /etc/os-release 2>/dev/null; then
        die "Este script foi feito para Arch Linux."
    fi
}

# Validate sudo access
check_sudo() {
    log_info "🔑 Validando permissões sudo..."
    if ! sudo -v; then
        die "Acesso sudo recusado. Você precisa de privilégios sudo."
    fi
}

# Check required dependencies
check_dependencies() {
    local required_cmds=(
        pacman sudo grep awk df ping tee mkdir rm cp sed mktemp getent
    )
    local missing=()
    
    for cmd in "${required_cmds[@]}"; do
        if ! is_installed "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Dependências ausentes: ${missing[*]}. Instale os pacotes necessários."
    fi
}

# ==============================================================================
# CONFIGURATION FILE SUPPORT
# ==============================================================================

# Load configuration from file
load_config() {
    local config_file="${1:-$WELLARCH_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        log_info "📄 Carregando configuração de $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
        return 0
    fi
    return 1
}

# Save current configuration to file
save_config() {
    local config_file="${1:-$WELLARCH_CONFIG_FILE}"
    
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << EOF
# WELLARCH Configuration File
# Generated on $(date '+%Y-%m-%d %H:%M:%S')

# AUR Helper: paru or yay
AUR_HELPER="${AUR_HELPER:-paru}"

# Pamac Package: pamac-all or pamac-aur
PAMAC_PKG="${PAMAC_PKG:-pamac-all}"

# DNS Provider: cloudflare, quad9, google, adguard, or none
DNS_PROVIDER="${DNS_PROVIDER:-cloudflare}"

# Skip flags (true/false)
SKIP_UPDATE="${SKIP_UPDATE:-false}"
SKIP_MIRRORS="${SKIP_MIRRORS:-false}"
SKIP_CHAOTIC="${SKIP_CHAOTIC:-false}"
SKIP_FLATPAK="${SKIP_FLATPAK:-false}"
SKIP_PAMAC="${SKIP_PAMAC:-false}"
SKIP_EXTRAS="${SKIP_EXTRAS:-false}"
SKIP_DNS="${SKIP_DNS:-false}"
SKIP_LINUXTOYS="${SKIP_LINUXTOYS:-false}"
SKIP_CLEANUP="${SKIP_CLEANUP:-false}"
# Restart system after installation
RESTART_SYSTEM="${RESTART_SYSTEM:-false}"

# Force resolv.conf lock
FORCE_RESOLV_LOCK="${FORCE_RESOLV_LOCK:-false}"

# Skip resolv.conf modifications
SKIP_RESOLV_CONF="${SKIP_RESOLV_CONF:-false}"
EOF
    
    log_success "Configuração salva em $config_file"
}

# ==============================================================================
# BACKUP, TEMP DIRS AND RESTORE
# ==============================================================================

declare -a BACKUP_FILES=()

# Array with temporary directories created during runtime. Tests and scripts
# append to this array and call `cleanup_temp_dirs` to remove them.
declare -a TMP_DIRS=()

backup_file() {
    local src="$1"
    local bak="${2:-${src}.wellarch.bak}"
    
    if [[ -f "$src" && ! -f "$bak" ]]; then
        if [[ $EUID -eq 0 ]]; then
            cp "$src" "$bak" || return 1
        else
            sudo cp "$src" "$bak" || return 1
        fi
        BACKUP_FILES+=("$src|$bak")
        log_info "📄 Backup criado: $bak"
    fi
}

restore_backups() {
    if [[ ${#BACKUP_FILES[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_warn "Restaurando backups críticos..."
    local pair src bak
    for pair in "${BACKUP_FILES[@]}"; do
        src="${pair%%|*}"
        bak="${pair##*|}"
        if [[ -f "$bak" ]]; then
            if [[ $EUID -eq 0 ]]; then
                cp "$bak" "$src" || true
            else
                sudo cp "$bak" "$src" || true
            fi
            log_info "Restaurado: $src"
        fi
    done
}

# ===========================================================================
# TEMPORARY DIRECTORY MANAGEMENT
# ===========================================================================

create_temp_dir() {
    local tmpdir
    tmpdir=$(mktemp -d)
    TMP_DIRS+=("$tmpdir")
    echo "$tmpdir"
}

cleanup_temp_dirs() {
    local d
    for d in "${TMP_DIRS[@]:-}"; do
        if [[ -n "$d" && "$d" == /* && -d "$d" ]]; then
            rm -rf -- "$d" 2>/dev/null || true
            log_debug "Removed temp dir: $d"
        fi
    done
    TMP_DIRS=()
}

# ==============================================================================
# SUDO KEEPALIVE
# ==============================================================================

SUDO_KEEPALIVE_PID=""

start_sudo_keepalive() {
    [[ -n "$SUDO_KEEPALIVE_PID" ]] && return 0
    
    (
        while true; do
            sudo -v 2>/dev/null || break
            sleep 60
        done
    ) &
    SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
        SUDO_KEEPALIVE_PID=""
    fi
}

# ==============================================================================
# CLEANUP HANDLER
# ==============================================================================

cleanup_handler() {
    stop_sudo_keepalive
    cleanup_temp_dirs
}

# Setup trap (call this in main scripts)
setup_cleanup_trap() {
    trap cleanup_handler EXIT INT TERM
}

# ==============================================================================
# COMMAND EXECUTION HELPERS
# ==============================================================================

# Run command with retry
run_with_retry() {
    local label="$1"
    shift
    local max_retries="${DOWNLOAD_RETRIES:-3}"
    local backoff="${DOWNLOAD_BACKOFF:-3}"
    local timeout="${DOWNLOAD_TIMEOUT:-300}"
    local attempt=1
    
    while true; do
        if [[ "$timeout" -gt 0 ]] && is_installed timeout; then
            if timeout "$timeout" "$@" 2>&1; then
                return 0
            fi
        else
            if "$@" 2>&1; then
                return 0
            fi
        fi
        
        if ((attempt >= max_retries)); then
            return 1
        fi
        
        log_warn "Tentativa ${attempt}/${max_retries} falhou. Aguardando ${backoff}s..."
        sleep "$backoff"
        ((attempt++))
        backoff=$((backoff * 2))
    done
}

# Run command as sudo
sudo_run() {
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Run command as sudo with retry
sudo_run_retry() {
    local label="$1"
    shift
    if [[ "${DRY_RUN:-false}" == true ]]; then
        return 0
    fi

    if [[ $EUID -eq 0 ]]; then
        run_with_retry "$label" "$@"
    else
        run_with_retry "$label" sudo "$@"
    fi
}

# ==============================================================================
# PROGRESS DISPLAY
# ==============================================================================

CURRENT_STEP=0
TOTAL_STEPS=15

show_progress() {
    local step_name="$1"
    ((CURRENT_STEP++))
    local bar_width=30
    local completed=$((CURRENT_STEP * bar_width / TOTAL_STEPS))
    local remaining=$((bar_width - completed))
    local bar=""
    local empty=""
    printf -v bar '%*s' "$completed" ''
    printf -v empty '%*s' "$remaining" ''
    bar=${bar// /#}
    empty=${empty// /-}
    printf "${PURPLE}[%s%s]${NC} ${GREEN}%02d/%02d %s${NC}\n" \
        "$bar" "$empty" "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
    log_to_file "[${CURRENT_STEP}/${TOTAL_STEPS}] ${step_name}"
}

reset_progress() {
    CURRENT_STEP=0
}

set_total_steps() {
    TOTAL_STEPS="$1"
}

# Detecta GPU presente no sistema. Retorna: intel|nvidia|amd|none|unknown
detect_gpu() {
    # Prefer lspci quando disponível
    local out=""
    if command -v lspci >/dev/null 2>&1; then
        out=$(lspci -nnk 2>/dev/null | tr '[:upper:]' '[:lower:]')
    elif command -v lshw >/dev/null 2>&1; then
        out=$(lshw -C display 2>/dev/null | tr '[:upper:]' '[:lower:]')
    else
        echo "unknown"
        return 0
    fi

    if echo "$out" | grep -q "nvidia"; then
        echo "nvidia"
        return 0
    fi
    if echo "$out" | grep -Eiq "amd|advanced micro devices|radeon|amdgpu"; then
        echo "amd"
        return 0
    fi
    if echo "$out" | grep -q "intel"; then
        echo "intel"
        return 0
    fi

    # No VGA/3D device found
    if [[ -z "$out" ]]; then
        echo "none"
    else
        echo "unknown"
    fi
}

# Detecta se a CPU é Intel (útil para recomendar pacotes como intel-ucode)
is_intel_cpu() {
    if grep -qi "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
        return 0
    fi
    return 1
}
