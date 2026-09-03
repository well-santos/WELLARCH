#!/bin/bash
# ==============================================================================
# WELLARCH Packages Module
# Pamac, themes, and extra applications.
# ==============================================================================

wellarch_install_pamac() {
    show_progress "Instalação do Pamac"

    if [[ "$SKIP_PAMAC" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando Pamac (--skip-pamac)${NC}"
        add_skipped_step "Instalação do Pamac"
        return 0
    fi

    if is_installed pamac; then
        echo "✅ Pamac já está instalado. Pulando."
        return 0
    fi

    echo "🛍️  Instalando $PAMAC_PKG..."
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo "(dry-run) pulando instalação do $PAMAC_PKG"
        return 0
    fi

    ensure_base_devel
    if ! $AUR_HELPER -S "$PAMAC_PKG" --noconfirm; then
        parar_com_erro "Instalação do $PAMAC_PKG"
    fi
    INSTALLED_PACKAGES+=("Pamac")
    record_installed_item pacman "$PAMAC_PKG"
    echo -e "${VERDE}✅ Pamac instalado!${NC}"
}

wellarch_install_extras() {
    show_progress "Temas, Aplicativos e Ferramentas"

    if [[ "$SKIP_EXTRAS" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando apps e temas essenciais (--skip-extras)${NC}"
        add_skipped_step "Apps e Temas Essenciais"
        return 0
    fi

    # Temas
    echo -e "${AZUL}🎨 Instalando Temas...${NC}"
    install_pkg_preferred "Cursor Fluent" "cursor-fluent" "fluent-cursor-theme"
    install_pkg_preferred "GNOME Themes Extra" "gnome-themes-extra"

    # Aplicativos
    echo -e "${AZUL}📱 Instalando Aplicativos...${NC}"
    install_pkg_preferred "GDM Settings" "gdm-settings"

    # Ferramentas de Desenvolvimento
    echo -e "${AZUL}⚙️  Instalando Ferramentas de Desenvolvimento...${NC}"
    install_pkg_preferred "Visual Studio Code" "visual-studio-code-bin"

    echo -e "${VERDE}✅ Temas, aplicativos e ferramentas instalados!${NC}"
}
