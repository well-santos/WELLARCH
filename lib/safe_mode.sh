#!/bin/bash
# ==============================================================================
# WELLARCH Safe Mode Guards
# Controls destructive system actions behind an explicit opt-in flag.
# ==============================================================================

# shellcheck disable=SC2034

safe_mode_enabled() {
    [[ "${SAFE_MODE:-true}" == true ]]
}

allow_destructive_action() {
    local action="${1:-operação}"

    if safe_mode_enabled; then
        log_warn "Modo seguro ativo: ação destrutiva bloqueada (${action}). Use --unsafe para permitir."
        return 1
    fi

    return 0
}

require_unsafe_confirmation() {
    local action="${1:-operação}"

    if safe_mode_enabled; then
        echo -e "${YELLOW}⚠️  Ação destrutiva bloqueada (${action}) em modo seguro.${NC}"
        echo -e "${YELLOW}   Use --unsafe para permitir explicitamente esta operação.${NC}"
        return 1
    fi

    return 0
}
