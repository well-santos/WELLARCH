#!/bin/bash

# Safer bash defaults
set -euo pipefail
IFS=$'\n\t'

# Log tudo para arquivo
LOGFILE="$HOME/.cache/wellarch/wellarch.log"
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# ==============================================================================
# DEFINIÇÃO DE CORES
# ==============================================================================
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;36m' # Ciano
ROXO='\033[0;35m'
NC='\033[0m' # Sem cor

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================
is_installed() {
    command -v "$1" &> /dev/null
}

parar_com_erro() {
    echo -e "${VERMELHO}❌ ERRO CRÍTICO: Falha na etapa: $1 ${NC}"
    echo -e "${VERMELHO}Script interrompido.${NC}"
    exit 1
}

# Cleanup/Trap
SUDO_KEEPALIVE_PID=""
TMP_DIRS=()
cleanup() {
    # kill sudo keepalive if running
    if [ -n "$SUDO_KEEPALIVE_PID" ]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    # remove temporary dirs
    for d in "${TMP_DIRS[@]:-}"; do
        [ -n "$d" ] && rm -rf "$d" || true
    done
}
trap cleanup EXIT ERR INT

# Helper to run commands and fail with message
run_cmd() {
    if ! "$@"; then
        parar_com_erro "Comando falhou: $*"
    fi
}

# Argumentos
DRY_RUN=false
ASSUME_YES=false
FORCE_RESOLV_LOCK=false
while [ $# -gt 0 ]; do
    case "${1-}" in
        --dry-run) DRY_RUN=true; shift ;;
        --yes|-y) ASSUME_YES=true; shift ;;
        --force-resolv-lock) FORCE_RESOLV_LOCK=true; shift ;;
        --help|-h)
            cat <<EOF
Usage: $0 [--dry-run] [--yes] [--force-resolv-lock]
  --dry-run           Não executa ações destrutivas, apenas mostra o que faria
  --yes, -y           Assume sim para prompts interativos
  --force-resolv-lock Ativa o chattr +i em /etc/resolv.conf (risco)
EOF
            exit 0
            ;;
        *) break ;;
    esac
done

# ==============================================================================
# PREPARAÇÃO VISUAL
# ==============================================================================
if ! is_installed figlet; then
    sudo pacman -S --needed figlet --noconfirm &> /dev/null
fi

clear
echo -e "${AZUL}"
if is_installed figlet; then
    figlet -f slant "WELLARCH"
else
    echo "WELLARCH v13.1"
fi
echo -e "${NC}"

echo -e "${ROXO}:: Automação, Pós-Instalação e Otimização para Arch Linux ::${NC}"
echo -e "👤 Desenvolvido para: ${AMARELO}Wesley${NC}"
echo -e "-------------------------------------------------------------"
echo -e "📝 ${VERDE}RESUMO DO QUE SERÁ FEITO:${NC}"
echo -e "   1. Paru & Chaotic AUR"
echo -e "   2. Flatpak & Flathub"
echo -e "   3. Apps Essenciais"
echo -e "   4. Pamac (via Paru)"
echo -e "   5. LinuxToys"
echo -e "   6. DNS Cloudflare (Método Nativo NetworkManager)"
echo -e "   7. Limpeza do Sistema"
echo -e "-------------------------------------------------------------"
echo ""

read -p "Deseja executar esse script? (y/n): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${VERMELHO}❌ Operação cancelada.${NC}"
    exit 0
fi

# ==============================================================================
# INÍCIO DA EXECUÇÃO
# ==============================================================================

echo ""
echo -e "${AMARELO}🚀 Iniciando WELLARCH v13.1...${NC}"

# 1. Checagem de Root
if [ "$EUID" -eq 0 ]; then
  echo -e "${VERMELHO}⚠️  Não rode como root. Use ./script.sh (o script pedirá a senha).${NC}"
  exit 1
fi

# Verifica se é Arch Linux
if ! grep -qi "arch" /etc/os-release; then
    echo -e "${VERMELHO}⚠️  Este script foi feito para Arch Linux. Saindo.${NC}"
    exit 1
fi

echo "🔑 Digite sua senha sudo para liberar as verificações:"
if ! sudo -v; then
    parar_com_erro "Sudo recusado"
fi

# Mantém sudo vivo (background) e guarda PID para cleanup
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!

# ---------------------------------------------------------
# 2. PARU (AUR HELPER)
# ---------------------------------------------------------
if is_installed paru; then
    echo "✅ Paru já está instalado. Pulando."
else
    echo "📦 Instalando Paru (Compilando do código fonte)..."
    run_cmd sudo pacman -S --needed base-devel git --noconfirm
    tmpdir=$(mktemp -d)
    TMP_DIRS+=("$tmpdir")
    run_cmd git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    pushd "$tmpdir/paru" >/dev/null
    if ! makepkg -si --noconfirm; then
        popd >/dev/null
        parar_com_erro "Instalação do Paru (makepkg)"
    fi
    popd >/dev/null
    rm -rf "$tmpdir"
    TMP_DIRS=()
    echo -e "${VERDE}✅ Paru instalado!${NC}"
fi

# ---------------------------------------------------------
# 3. CHAOTIC AUR
# ---------------------------------------------------------
if grep -q "chaotic-aur" /etc/pacman.conf; then
    echo "✅ Chaotic AUR já está configurado. Pulando."
else
    echo "🌀 Configurando Chaotic AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    run_cmd sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    run_cmd sudo pacman -Sy --noconfirm
    echo -e "${VERDE}✅ Chaotic AUR configurado!${NC}"
fi

# ---------------------------------------------------------
# 4. FLATPAK & FLATHUB
# ---------------------------------------------------------
if is_installed flatpak; then
    echo "✅ Flatpak já está instalado."
else
    echo "📦 Instalando Flatpak..."
    sudo pacman -S flatpak --noconfirm
fi

if flatpak remote-list | grep -q "flathub"; then
    echo "✅ Repositório Flathub já ativo. Pulando."
else
    echo "🌐 Adicionando Flathub..."
    run_cmd flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo -e "${VERDE}✅ Flathub configurado!${NC}"
fi

# ---------------------------------------------------------
# 5. APPS FLATPAK
# ---------------------------------------------------------
echo "📱 Verificando aplicativos..."
APPS_FLATPAK=(
    "com.rtosta.zapzap"
    "org.telegram.desktop"
    "com.vysp3r.ProtonPlus"
    "org.equicord.equibop"
    "com.github.wwmm.easyeffects"
    "io.github.flattool.Ignition"
    "com.brave.Browser"
    "com.mattjakeman.ExtensionManager"
)

for APP in "${APPS_FLATPAK[@]}"; do
    if flatpak list --app | grep -q "$APP"; then
        echo -e "   ℹ️  $APP já instalado. Pulando."
    else
        echo -e "   ⬇️  Instalando $APP..."
        if [ "$DRY_RUN" = true ]; then
            echo "   (dry-run) pulando instalação de $APP"
        else
            if ! flatpak install flathub "$APP" -y; then
                echo -e "   ${AMARELO}⚠️  Erro. Reparando e tentando novamente...${NC}"
                sudo flatpak repair || true
                flatpak install flathub "$APP" -y || echo "Falha ao instalar $APP"
            fi
        fi
    fi
done

# ---------------------------------------------------------
# 6. PAMAC (via Paru)
# ---------------------------------------------------------
if is_installed pamac; then
    echo "✅ Pamac já está instalado. Pulando."
else
    echo "🛍️  Instalando Pamac-all..."
    if [ "$DRY_RUN" = true ]; then
        echo "(dry-run) pulando instalação do pamac-all"
    else
        if ! paru -S pamac-all --noconfirm; then
            parar_com_erro "Instalação do Pamac-all"
        fi
    fi
    echo -e "${VERDE}✅ Pamac instalado!${NC}"
fi

# ---------------------------------------------------------
# 7. LINUXTOYS
# ---------------------------------------------------------
MARKER_FILE="$HOME/.config/linuxtoys_installed.marker"

if [ -f "$MARKER_FILE" ]; then
    echo "✅ LinuxToys já foi executado. Pulando."
else
    echo "🧸 Instalando LinuxToys..."
    DEPS=(bash git curl wget zenity python python-gobject python-requests gtk3 vte3)
    run_cmd sudo pacman -S --needed "${DEPS[@]}" --noconfirm

    lt_tmp=$(mktemp -d)
    TMP_DIRS+=("$lt_tmp")
    lt_script="$lt_tmp/linuxtoys-install.sh"
    if ! curl -fsSL -o "$lt_script" https://linux.toys/install.sh; then
        echo -e "${VERMELHO}⚠️ Falha ao baixar LinuxToys.${NC}"
    else
        echo "Script LinuxToys salvo em: $lt_script"
        if [ "$ASSUME_YES" = true ]; then
            bash "$lt_script"
        else
            read -p "Executar o instalador do LinuxToys agora? (y/n): " anslt
            if [[ "$anslt" =~ ^[yY]$ ]]; then
                bash "$lt_script"
            else
                echo "Pulando execução do instalador LinuxToys (arquivo baixado)."
            fi
        fi
        if [ $? -eq 0 ]; then
            touch "$MARKER_FILE"
            echo -e "${VERDE}✅ LinuxToys instalado e marcador criado!${NC}"
        else
            echo -e "${VERMELHO}⚠️ Falha no LinuxToys.${NC}"
        fi
    fi
    rm -rf "$lt_tmp"
    TMP_DIRS=()
fi

# ---------------------------------------------------------
# 8. DNS CLOUDFLARE (SOLUÇÃO DEFINITIVA NETWORK MANAGER)
# ---------------------------------------------------------
echo "🌐 Configurando DNS Cloudflare..."
NM_CONF="/etc/NetworkManager/conf.d/99-cloudflare-dns.conf"

# Verifica se a configuração nativa do NM já existe
if [ -f "$NM_CONF" ] && grep -q "2606:4700:4700::1111" "$NM_CONF"; then
    echo "✅ Configuração Global do NetworkManager já aplicada. Pulando."
else
    echo "⚙️  Aplicando DNS IPv4/IPv6 diretamente no NetworkManager..."
    
    # 1. Cria a pasta se não existir
    run_cmd sudo mkdir -p /etc/NetworkManager/conf.d/

    # 2. Cria arquivo de configuração global (não trava resolv.conf por padrão)
    # A sintaxe [global-dns-domain-*] aplica para todos os domínios
    sudo tee "$NM_CONF" > /dev/null <<EOF
[main]
dns=default

[global-dns-domain-*]
servers=1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001
EOF
    echo "   📄 Configuração do NetworkManager criada."

    # 3. Atualiza resolv.conf localmente (sem travar) — instruções para lock abaixo
    RESOLV_CONF="/etc/resolv.conf"
    sudo rm -f "$RESOLV_CONF" || true
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 2606:4700:4700::1111\nnameserver 2606:4700:4700::1001\n" | sudo tee "$RESOLV_CONF" > /dev/null
    if [ "$FORCE_RESOLV_LOCK" = true ]; then
        echo "   🔒 Travando resolv.conf (opção forçada)."
        sudo chattr +i "$RESOLV_CONF"
    else
        echo "   ⚠️  resolv.conf atualizado, mas não travado. Use --force-resolv-lock para travar com chattr +i (não recomendado)."
    fi

    # 4. Reinicia o NetworkManager para aplicar
    echo "   🔄 Reiniciando serviço de rede..."
    run_cmd sudo systemctl restart NetworkManager

    echo -e "${VERDE}✅ DNS Cloudflare IPv4 e IPv6 aplicado nativamente!${NC}"
fi

# ---------------------------------------------------------
# 9. LIMPEZA
# ---------------------------------------------------------
echo ""
echo -e "${AZUL}🧹 Limpeza do Sistema...${NC}"

sudo pacman -S --needed pacman-contrib --noconfirm &> /dev/null

echo "   📦 Limpando cache do Pacman..."
sudo paccache -rk 2 > /dev/null 2>&1

if [ "$DRY_RUN" = true ]; then
    echo "   (dry-run) pulando pacman -Sc destrutivo"
else
    echo "   Remoção adicional de caches antigos é opcional; mantendo configuração segura (paccache -rk 2)."
fi

mapfile -t ORPHANS < <(pacman -Qdtq || true)
if [ ${#ORPHANS[@]} -gt 0 ]; then
    echo "   🗑️  Órfãos encontrados: ${ORPHANS[*]}"
    if [ "$ASSUME_YES" = true ]; then
        run_cmd sudo pacman -Rns ${ORPHANS[*]} --noconfirm
        echo -e "   ${VERDE}✅ Órfãos removidos.${NC}"
    else
        read -p "Remover pacotes órfãos acima? (y/n): " ansor
        if [[ "$ansor" =~ ^[yY]$ ]]; then
            run_cmd sudo pacman -Rns ${ORPHANS[*]} --noconfirm
            echo -e "   ${VERDE}✅ Órfãos removidos.${NC}"
        else
            echo "   ✅ Pulando remoção de órfãos."
        fi
    fi
else
    echo "   ✅ Nenhum órfão encontrado."
fi

echo "   🦄 Limpando cache do Paru..."
if ! paru -c --noconfirm > /dev/null 2>&1; then
    echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do Paru (paru -c).${NC}"
fi
if ! paru -Sc --noconfirm > /dev/null 2>&1; then
    echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do Paru (paru -Sc).${NC}"
fi

echo "   📱 Limpando Flatpaks..."
flatpak uninstall --unused -y > /dev/null 2>&1

echo "   📜 Limpando logs..."
sudo journalctl --vacuum-time=7d > /dev/null 2>&1

echo ""
echo -e "${VERDE}✨🎉 SETUP COMPLETO! SISTEMA OTIMIZADO. 🎉✨${NC}"