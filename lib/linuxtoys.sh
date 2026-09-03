#!/bin/bash
# ==============================================================================
# WELLARCH LinuxToys Module
# LinuxToys installation and setup.
# ==============================================================================

wellarch_install_linuxtoys() {
    show_progress "Instalação do LinuxToys"

    local marker_file="$HOME/.config/linuxtoys_installed.marker"

    if [[ "$SKIP_LINUXTOYS" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando LinuxToys (--skip-linuxtoys)${NC}"
        add_skipped_step "Instalação do LinuxToys"
        return 0
    fi

    if [[ -f "$marker_file" ]]; then
        echo "✅ LinuxToys já foi executado. Pulando."
        return 0
    fi

    echo "🧸 Instalando LinuxToys..."
    if [[ "${DRY_RUN:-false}" == true ]]; then
        echo -e "${AMARELO}(dry-run) verificaria dependências e download do LinuxToys${NC}"
        return 0
    fi

    # Instalar dependências
    local deps=(bash git curl wget zenity python python-gobject python-requests gtk3 vte3)
    if ! sudo_run_retry "Instalação de dependências do LinuxToys" pacman -S --needed "${deps[@]}" --noconfirm; then
        echo -e "${AMARELO}⚠️ Falha ao instalar dependências do LinuxToys.${NC}"
        FAILED_ITEMS+=("LinuxToys (deps)")
        return 1
    fi

    # Download do script
    local lt_tmp
    lt_tmp=$(mktemp -d)
    TMP_DIRS+=("$lt_tmp")
    local lt_script="$lt_tmp/linuxtoys-install.sh"
    local curl_opts=(-fsSL --connect-timeout 10)
    if [[ "${DOWNLOAD_TIMEOUT:-0}" -gt 0 ]]; then
        curl_opts+=(--max-time "$DOWNLOAD_TIMEOUT")
    fi

    if ! run_with_retry "Download do LinuxToys" curl "${curl_opts[@]}" -o "$lt_script" https://linux.toys/install.sh; then
        echo -e "${VERMELHO}⚠️ Falha ao baixar LinuxToys.${NC}"
        FAILED_ITEMS+=("LinuxToys")
        return 1
    fi

    echo "Script LinuxToys salvo em: $lt_script"

    # Verificar checksum
    local lt_ok=false
    if [[ -n "${LINUXTOYS_SHA256:-}" ]]; then
        if echo "${LINUXTOYS_SHA256}  $lt_script" | sha256sum -c --status 2>/dev/null; then
            echo "   ✅ Checksum do LinuxToys verificado."
        else
            echo -e "${VERMELHO}❌ Checksum do LinuxToys não confere. Abortando execução.${NC}"
            FAILED_ITEMS+=("LinuxToys (checksum)")
            return 1
        fi
    else
        echo -e "${VERMELHO}❌ LINUXTOYS_SHA256 não definido; recusando execução.${NC}"
        FAILED_ITEMS+=("LinuxToys (checksum ausente)")
        return 1
    fi

    # Executar o instalador
    if [[ "$ASSUME_YES" == true ]]; then
        if run_quiet_with_progress "Instalando LinuxToys" bash "$lt_script"; then
            lt_ok=true
        fi
    else
        read -r -p "Executar o instalador do LinuxToys agora? (y/n): " anslt
        if [[ "$anslt" =~ ^[yY]$ ]] && bash "$lt_script"; then
            lt_ok=true
        fi
    fi

    # Criar marcador de sucesso
    if [[ "$lt_ok" == true ]]; then
        touch "$marker_file"
        echo -e "${VERDE}✅ LinuxToys instalado e marcador criado!${NC}"
        INSTALLED_PACKAGES+=("LinuxToys")
        return 0
    else
        echo -e "${VERMELHO}⚠️ Falha no LinuxToys.${NC}"
        FAILED_ITEMS+=("LinuxToys")
        return 1
    fi
}
