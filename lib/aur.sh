#!/bin/bash
# ==============================================================================
# WELLARCH AUR Module
# Refactored AUR-related functions.
# ==============================================================================

wellarch_setup_chaotic_aur() {
    if [[ "$SKIP_CHAOTIC" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando Chaotic AUR (--skip-chaotic)${NC}"
        add_skipped_step "Configuração do Chaotic AUR"
        return 0
    fi

    if grep -q "chaotic-aur" /etc/pacman.conf; then
        echo "✅ Chaotic AUR já está configurado. Pulando."
        return 0
    fi
    echo "🌀 Configurando Chaotic AUR..."
    backup_file /etc/pacman.conf /etc/pacman.conf.bak
    echo "   📝 Backup de /etc/pacman.conf criado em /etc/pacman.conf.bak"

    sudo_run pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo_run pacman-key --lsign-key 3056513887B78AEB
    if ! sudo_run_retry "Configuração do Chaotic AUR (pacman -U)" pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm; then
        parar_com_erro "Configuração do Chaotic AUR (pacman -U)"
    fi
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo_run tee -a /etc/pacman.conf >/dev/null
    if ! sudo_run_retry "Configuração do Chaotic AUR (pacman -Sy)" pacman -Sy --noconfirm; then
        parar_com_erro "Configuração do Chaotic AUR (pacman -Sy)"
    fi
    echo -e "${VERDE}✅ Chaotic AUR configurado!${NC}"
    INSTALLED_PACKAGES+=("Chaotic AUR")
}

wellarch_install_aur_helper() {
    if is_installed "$AUR_HELPER"; then
        echo "✅ $AUR_HELPER já está instalado. Pulando."
        return 0
    fi
    echo "📦 Instalando $AUR_HELPER..."

    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${AMARELO}(dry-run) pulando instalação do $AUR_HELPER${NC}"
        return 0
    fi

    if sudo_run_retry "Instalação do $AUR_HELPER (pacman)" pacman -S "$AUR_HELPER" --noconfirm 2>/dev/null; then
        echo -e "${VERDE}✅ $AUR_HELPER instalado via repositório!${NC}"
        INSTALLED_PACKAGES+=("$AUR_HELPER")
        return 0
    fi

    echo "📦 Instalando $AUR_HELPER-bin do AUR..."
    if ! sudo_run_retry "Instalação de base-devel/git" pacman -S --needed base-devel git --noconfirm; then
        parar_com_erro "Instalação de base-devel/git"
    fi
    local tmpdir
    tmpdir=$(mktemp -d)
    TMP_DIRS+=("$tmpdir")

    if ! run_with_retry "Clone do $AUR_HELPER-bin" git clone "https://aur.archlinux.org/${AUR_HELPER}-bin.git" "$tmpdir/$AUR_HELPER"; then
        parar_com_erro "Clone do $AUR_HELPER-bin"
    fi
    pushd "$tmpdir/$AUR_HELPER" >/dev/null || return 1

    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${AMARELO}(dry-run) pulando makepkg para $AUR_HELPER${NC}"
    else
        if ! makepkg -si --noconfirm; then
            popd >/dev/null
            parar_com_erro "Instalação do $AUR_HELPER (makepkg)"
        fi
    fi

    popd >/dev/null
    if [[ "$tmpdir" == /* && -d "$tmpdir" ]]; then
        rm -rf -- "$tmpdir"
    fi
    TMP_DIRS=()
    echo -e "${VERDE}✅ $AUR_HELPER instalado via AUR!${NC}"
    INSTALLED_PACKAGES+=("$AUR_HELPER")
}
