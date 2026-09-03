#!/bin/bash
# ==============================================================================
# WELLARCH DNS Module
# DNS setup helpers.
# ==============================================================================

wellarch_setup_dns() {
    show_progress "Configuração de DNS"

    if [[ "$SKIP_DNS" == true ]]; then
        echo -e "${AMARELO}⏭️  Pulando configuração de DNS (--skip-dns)${NC}"
        add_skipped_step "Configuração de DNS"
        return 0
    fi

    if [[ "$DNS_PROVIDER" == "none" ]]; then
        echo "⏭️ DNS: Mantendo configuração padrão do sistema."
        add_skipped_step "Configuração de DNS (padrão do sistema)"
        return 0
    fi

    if [[ -z "${DNS_SERVERS:-}" ]]; then
        echo -e "${AMARELO}⚠️ DNS_SERVERS vazio; pulando configuração de DNS.${NC}"
        return 0
    fi

    echo "🌐 Configurando DNS (IPv4 e IPv6)..."
    NM_CONF="/etc/NetworkManager/conf.d/99-dns-provider.conf"
    RESOLV_CONF="/etc/resolv.conf"
    RESOLV_BACKUP="/etc/resolv.conf.wellarch.bak"
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet systemd-resolved; then
            log_warn "systemd-resolved está ativo; /etc/resolv.conf pode ser gerenciado automaticamente."
            if [[ "$SKIP_RESOLV_CONF" == true ]]; then
                log_warn "Pulando alterações em /etc/resolv.conf (--skip-resolv-conf)."
            fi
        fi
    fi

    IFS=',' read -ra SERVERS <<<"$DNS_SERVERS"
    IPV4_SERVERS=()
    IPV6_SERVERS=()
    for server in "${SERVERS[@]}"; do
        if [[ "$server" == *:* ]]; then
            IPV6_SERVERS+=("$server")
        else
            IPV4_SERVERS+=("$server")
        fi
    done

    sudo_run mkdir -p /etc/NetworkManager/conf.d/
    NM_SERVERS="${DNS_SERVERS//,/ }"
    sudo_run tee "$NM_CONF" >/dev/null <<EOF
[main]
dns=default

[global-dns-domain-*]
servers=$NM_SERVERS
EOF
    echo "   📄 Configuração do NetworkManager criada para $DNS_PROVIDER."

    if [[ "$SKIP_RESOLV_CONF" != true ]]; then
        backup_file "$RESOLV_CONF" "$RESOLV_BACKUP"
        if [[ -f "$RESOLV_BACKUP" ]]; then
            echo "   🗂️  Backup de resolv.conf salvo em $RESOLV_BACKUP"
        fi

        if [[ -L "$RESOLV_CONF" ]]; then
            echo "   ℹ️  resolv.conf é symlink; substituindo por arquivo gerenciado pelo WELLARCH."
            sudo_run rm -f "$RESOLV_CONF"
        fi

        sudo_run rm -f "$RESOLV_CONF" || true

        for server in "${SERVERS[@]}"; do
            printf "nameserver %s\n" "$server" | sudo_run tee -a "$RESOLV_CONF" >/dev/null
        done

        if [[ "$FORCE_RESOLV_LOCK" == true ]]; then
            echo "   🔒 Travando resolv.conf (opção forçada)."
            sudo_run chattr +i "$RESOLV_CONF"
        else
            echo "   ℹ️  resolv.conf atualizado. Use --force-resolv-lock para travar (não recomendado)."
        fi
    fi

    if command -v nmcli >/dev/null 2>&1; then
        mapfile -t ACTIVE_CONNS < <(nmcli -t -f NAME connection show --active)
        if [[ ${#ACTIVE_CONNS[@]} -eq 0 ]]; then
            echo "   ⚠️ Nenhuma conexão ativa encontrada para aplicar DNS via nmcli."
        else
            for CONN in "${ACTIVE_CONNS[@]}"; do
                echo "   🔧 Aplicando DNS na conexão: $CONN"
                if [[ "${DRY_RUN:-false}" == true ]]; then
                    echo "   (dry-run) não modificando a conexão $CONN"
                    continue
                fi
                nmcli connection modify "$CONN" ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes 2>/dev/null || true
                if [[ ${#IPV4_SERVERS[@]} -gt 0 ]]; then
                    nmcli connection modify "$CONN" ipv4.dns "${IPV4_SERVERS[*]}" 2>/dev/null || true
                fi
                if [[ ${#IPV6_SERVERS[@]} -gt 0 ]]; then
                    nmcli connection modify "$CONN" ipv6.dns "${IPV6_SERVERS[*]}" 2>/dev/null || true
                fi
                nmcli connection up "$CONN" >/dev/null 2>&1 || nmcli connection reload >/dev/null 2>&1 || true
            done
        fi
    else
        echo "   ⚠️ nmcli não encontrado; apenas resolv.conf foi atualizado."
    fi

    echo "   🔄 Reiniciando NetworkManager..."
    sudo_run systemctl restart NetworkManager

    echo -e "${VERDE}✅ DNS configurado (IPv4/IPv6)!${NC}"
    INSTALLED_PACKAGES+=("DNS: $DNS_PROVIDER")
}
