#!/bin/bash
# ==============================================================================
# WELLARCH System Setup Module
# Extra system configuration helpers.
# ==============================================================================

wellarch_configure_oh_my_zsh() {
    install_pkg_preferred "Zsh" "zsh"
    install_pkg_preferred "Git" "git"
    install_pkg_preferred "Curl" "curl"

    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${AMARELO}(dry-run) instalaria Oh My Zsh e aplicaria tema duellj${NC}"
        return 0
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        echo "🌀 Instalando Oh My Zsh..."
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    else
        echo "✅ Oh My Zsh já instalado."
    fi

    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="duellj"/' "$HOME/.zshrc"
        else
            echo 'ZSH_THEME="duellj"' >> "$HOME/.zshrc"
        fi
        echo -e "${VERDE}✅ Tema do Oh My Zsh definido para duellj${NC}"
    else
        echo -e "${AMARELO}⚠️ ~/.zshrc não encontrado; tema do Oh My Zsh não aplicado.${NC}"
    fi

    if is_installed zsh; then
        if [[ "$SHELL" != */zsh ]]; then
            if command -v chsh >/dev/null 2>&1; then
                chsh -s "$(command -v zsh)" "$USER" >/dev/null 2>&1 || true
                echo -e "${VERDE}✅ Zsh definido como shell padrão (faça logout/login).${NC}"
            else
                echo -e "${AMARELO}⚠️ chsh não disponível; zsh não definido como padrão.${NC}"
            fi
        fi
    fi

    if command -v gsettings >/dev/null 2>&1; then
        profile_id=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null || true)
        profile_id=${profile_id//\'/}
        if [[ -n "$profile_id" ]]; then
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/" use-custom-command false >/dev/null 2>&1 || true
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/" custom-command "" >/dev/null 2>&1 || true
            gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/" login-shell true >/dev/null 2>&1 || true
            echo -e "${VERDE}✅ GNOME Terminal configurado para usar o shell padrão (login).${NC}"
        fi
    fi
}

wellarch_cleanup_system() {
    show_progress "Limpeza do Sistema"

    if [[ "$SKIP_CLEANUP" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando limpeza (--skip-cleanup)${NC}"
        add_skipped_step "Limpeza do Sistema"
        return 0
    fi

    if ! allow_destructive_action "Limpeza do Sistema"; then
        echo -e "${AMARELO}⏭️  Modo seguro ativo: limpeza do sistema bloqueada.${NC}"
        add_skipped_step "Limpeza do Sistema (modo seguro)"
        return 0
    fi

    echo -e "${AZUL}🧹 Limpeza do Sistema...${NC}"

    if ! sudo_run_retry "Instalação do pacman-contrib" pacman -S --needed pacman-contrib --noconfirm &>/dev/null; then
        echo -e "${AMARELO}⚠️  Falha ao instalar pacman-contrib.${NC}"
    fi

    echo "   📦 Limpando cache do Pacman..."
    sudo_run paccache -rk 2 >/dev/null 2>&1

    if [[ "$DRY_RUN" == true ]]; then
        echo "   (dry-run) pulando pacman -Sc destrutivo"
    else
        echo "   Remoção adicional de caches antigos é opcional; mantendo configuração segura (paccache -rk 2)."
    fi

    mapfile -t ORPHANS < <(pacman -Qdtq || true)
    if [[ ${#ORPHANS[@]} -gt 0 ]]; then
        echo "   🗑️ Órfãos encontrados: ${ORPHANS[*]}"
        if [[ "$ASSUME_YES" == true ]]; then
            sudo_run pacman -Rns "${ORPHANS[@]}" --noconfirm
            echo -e "   ${VERDE}✅ Órfãos removidos.${NC}"
        else
            read -r -p "Remover pacotes órfãos acima? (y/n): " ansor
            if [[ "$ansor" =~ ^[yY]$ ]]; then
                sudo_run pacman -Rns "${ORPHANS[@]}" --noconfirm
                echo -e "   ${VERDE}✅ Órfãos removidos.${NC}"
            else
                echo "   ✅ Pulando remoção de órfãos."
            fi
        fi
    else
        echo "   ✅ Nenhum órfão encontrado."
    fi

    echo "   🦄 Limpando cache do AUR Helper..."
    if [[ "$DRY_RUN" == true ]]; then
        echo "   (dry-run) pulando limpeza do cache do $AUR_HELPER"
    elif is_installed "$AUR_HELPER"; then
        if ! $AUR_HELPER -c --noconfirm >/dev/null 2>&1; then
            echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do $AUR_HELPER (-c).${NC}"
        fi
        if ! $AUR_HELPER -Sc --noconfirm >/dev/null 2>&1; then
            echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do $AUR_HELPER (-Sc).${NC}"
        fi
    else
        echo "   ℹ️  $AUR_HELPER não encontrado; pulando limpeza do cache."
    fi

    echo "   📱 Limpando Flatpaks..."
    if is_installed flatpak; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "   (dry-run) pulando limpeza de runtimes Flatpak"
        else
            flatpak uninstall --unused -y >/dev/null 2>&1 || true
        fi
    else
        echo "   ℹ️  Flatpak não instalado; pulando limpeza."
    fi

    echo "   📜 Limpando logs..."
    sudo_run journalctl --vacuum-time=7d >/dev/null 2>&1
}
