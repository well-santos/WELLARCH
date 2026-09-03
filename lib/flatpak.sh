#!/bin/bash
# ==============================================================================
# WELLARCH Flatpak Module
# Flatpak and app installation helpers.
# ==============================================================================

wellarch_setup_flatpak() {
    show_progress "Configuração do Flatpak"

    if [[ "$SKIP_FLATPAK" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando Flatpak (--skip-flatpak)${NC}"
        add_skipped_step "Configuração do Flatpak"
        return 0
    fi

    if ! is_installed flatpak; then
        echo "📦 Instalando Flatpak..."
        if ! sudo_run_retry "Instalação do Flatpak" pacman -S flatpak --noconfirm; then
            echo -e "${AMARELO}⚠️ Falha ao instalar Flatpak.${NC}"
            FAILED_ITEMS+=("Flatpak")
            return 0
        fi
        INSTALLED_PACKAGES+=("Flatpak")
        record_installed_item pacman flatpak
    else
        echo "✅ Flatpak já está instalado."
    fi

    if ! flatpak remote-list 2>/dev/null | grep -q "flathub"; then
        echo "🌐 Adicionando Flathub..."
        if ! run_with_retry "Configuração do Flathub" flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
            echo -e "${AMARELO}⚠️ Falha ao adicionar Flathub.${NC}"
            FAILED_ITEMS+=("Flathub")
            return 0
        fi
        echo -e "${VERDE}✅ Flathub configurado!${NC}"
    else
        echo "✅ Repositório Flathub já ativo. Pulando."
    fi
}

wellarch_install_flatpak_apps() {
    show_progress "Instalação de Apps Flatpak"

    if [[ "$SKIP_FLATPAK" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando apps Flatpak (--skip-flatpak)${NC}"
        add_skipped_step "Apps Flatpak"
        return 0
    fi

    if [[ ${#SELECTED_APPS[@]} -gt 0 ]]; then
        echo "📱 Instalando aplicativos Flatpak selecionados..."
        for APP in "${SELECTED_APPS[@]}"; do
            if flatpak list --app | grep -Fxq "$APP"; then
                echo -e "   ℹ️  $APP já instalado. Pulando."
            else
                echo -e "   ⬇️  Instalando $APP..."
                if [[ "$DRY_RUN" == true ]]; then
                    echo "   (dry-run) pulando instalação de $APP"
                else
                    if run_with_retry "Instalação do Flatpak $APP" flatpak install flathub "$APP" -y; then
                        INSTALLED_FLATPAKS+=("$APP")
                        record_installed_item flatpak "$APP"
                    else
                        echo -e "   ${AMARELO}⚠️  Erro. Reparando e tentando novamente...${NC}"
                        sudo_run flatpak repair || true
                        if run_with_retry "Instalação do Flatpak $APP (retry)" flatpak install flathub "$APP" -y; then
                            INSTALLED_FLATPAKS+=("$APP")
                            record_installed_item flatpak "$APP"
                        else
                            echo -e "   ${VERMELHO}❌ Falha ao instalar $APP${NC}"
                            FAILED_ITEMS+=("$APP")
                        fi
                    fi
                fi
            fi
        done
    else
        echo "ℹ️  Nenhum aplicativo Flatpak selecionado para instalar."
    fi
}
