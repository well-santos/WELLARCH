#!/bin/bash
# ==============================================================================
# WELLARCH System Setup Helpers
# Common operations for Arch setup and validation.
# ==============================================================================

# shellcheck disable=SC2034

check_internet() {
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null && ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        die "Sem conexão com internet. Verifique sua conexão de rede."
    fi
}

check_disk_space() {
    local path="${1:-$HOME}"
    local required_kb="${2:-$((3 * 1024 * 1024))}"
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

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        die "Não execute como root. O script pedirá a senha quando necessário."
    fi
}

check_arch_linux() {
    if ! grep -qi "arch" /etc/os-release 2>/dev/null; then
        die "Este script foi feito para Arch Linux."
    fi
}

check_sudo() {
    log_info "🔑 Validando permissões sudo..."
    if ! sudo -v; then
        die "Acesso sudo recusado. Você precisa de privilégios sudo."
    fi
}

check_dependencies() {
    local required_cmds=(
        pacman sudo grep awk df ping tee mkdir rm cp sed mktemp
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
