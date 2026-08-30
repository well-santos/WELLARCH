#!/bin/bash
# ==============================================================================
# WELLARCH Mirrors Module
# Reflector and mirror optimization helpers.
# ==============================================================================

wellarch_setup_reflector() {
    show_progress "Otimização de Mirrors"

    if [[ "$SKIP_MIRRORS" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando otimização de mirrors (--skip-mirrors)${NC}"
        add_skipped_step "Otimização de Mirrors"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${AMARELO}(dry-run) pulando atualização de mirrors com reflector${NC}"
        return 0
    fi

    if ! allow_destructive_action "Otimização de Mirrors"; then
        echo -e "${AMARELO}⏭️  Modo seguro ativo: otimização de mirrors bloqueada.${NC}"
        add_skipped_step "Otimização de Mirrors (modo seguro)"
        return 0
    fi

    if ! is_installed reflector; then
        echo "🔧 Instalando reflector para ordenação de mirrors..."
        sudo_run_retry "Instalação do reflector" pacman -S --needed reflector --noconfirm || {
            echo -e "${AMARELO}⚠️ Não foi possível instalar reflector automaticamente.${NC}"
            return 0
        }
    else
        echo "✅ reflector já instalado."
    fi

    if is_installed reflector; then
        echo "🔄 Atualizando /etc/pacman.d/mirrorlist priorizando Brasil..."
        backup_file /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.wellarch.bak
        if ! sudo_run reflector --country Brazil --protocol https --latest 20 --sort rate --age 24 --save /etc/pacman.d/mirrorlist; then
            echo -e "${AMARELO}⚠️ Falha ao executar reflector com país Brasil; mantendo mirrorlist atual.${NC}"
            return 0
        fi
        sudo_run_retry "Atualização de mirrors (pacman -Syy)" pacman -Syy --noconfirm || true
        echo -e "${VERDE}✅ Mirrors otimizados!${NC}"
        INSTALLED_PACKAGES+=("Reflector")
    fi
}
