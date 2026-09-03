#!/bin/bash
# ==============================================================================
# WELLARCH Remover v15.1.0
# Script para remover/desfazer alterações do WELLARCH
# ==============================================================================

# Ativa tratamento rigoroso de erros
set -euo pipefail
IFS=$'\n\t'

# Script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library if available
if [[ -f "${SCRIPT_DIR}/lib/common.sh" ]]; then
    # shellcheck source=lib/common.sh
    source "${SCRIPT_DIR}/lib/common.sh"
    USING_COMMON_LIB=true
else
    USING_COMMON_LIB=false
    
    # Inline definitions
    if [[ -t 1 ]]; then
        VERDE='\033[0;32m'
        VERMELHO='\033[0;31m'
        AMARELO='\033[1;33m'
        AZUL='\033[0;36m'
        ROXO='\033[0;35m'
        NC='\033[0m'
    else
        VERDE='' VERMELHO='' AMARELO='' AZUL='' ROXO='' NC=''
    fi
    
    parar_com_erro() {
        echo -e "${VERMELHO}❌ ERRO: $1 ${NC}"
        exit 1
    }
    
    is_installed() {
        command -v "$1" &> /dev/null
    }
    
    is_pkg_installed() {
        pacman -Qi "$1" >/dev/null 2>&1
    }
fi

VERSION="${WELLARCH_VERSION:-15.1.0}"
LOGFILE="${HOME}/.cache/wellarch/wellarch-remove.log"
mkdir -p "$(dirname "$LOGFILE")"

if [[ "$USING_COMMON_LIB" != true ]]; then
    # Logging (fallbacks when common lib isn't available)
    log_to_file() {
        echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $*" >> "$LOGFILE"
    }

    log_info() {
        echo -e "${AZUL}$*${NC}"
        log_to_file "[INFO] $*"
    }

    log_success() {
        echo -e "${VERDE}✓ $*${NC}"
        log_to_file "[SUCCESS] $*"
    }

    log_warn() {
        echo -e "${AMARELO}⚠️ $*${NC}"
        log_to_file "[WARN] $*"
    }
fi

# ==============================================================================
# VERIFICAÇÕES INICIAIS
# ==============================================================================
clear
echo -e "${AZUL}"
echo "WELLARCH REMOVER v${VERSION}"
echo -e "${NC}"
echo -e "${ROXO}:: Script de Desinstalação para WELLARCH ::${NC}"
echo -e "-------------------------------------------------------------"
echo -e "${VERMELHO}⚠️  AVISO: Este script removerá alterações feitas pelo WELLARCH${NC}"
echo ""

log_to_file "=== WELLARCH REMOVER v${VERSION} iniciado ==="

# Valida root
if [ "$EUID" -eq 0 ]; then
  echo -e "${VERMELHO}⚠️  Não rode como root. Use ./wellarch-remove.sh${NC}"
  exit 1
fi

# Pede confirmação
read -rp "Tem certeza que deseja remover as alterações do WELLARCH? (y/n): " confirm
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo -e "${VERDE}Operação cancelada.${NC}"
    exit 0
fi

if ! sudo -v; then
    parar_com_erro "Acesso sudo recusado. Você precisa de privilégios sudo."
fi

echo -e "${AMARELO}🗑️  Iniciando remoção...${NC}"
echo ""

# ==============================================================================
# LÓGICA DE REMOÇÃO
# ==============================================================================

# 1. Remover Paru ou Yay
echo -e "${AZUL}1. Removendo AUR Helper...${NC}"
if is_installed paru; then
    echo "   Removendo Paru..."
    sudo pacman -Rns paru --noconfirm || true
    echo -e "   ${VERDE}✓ Paru removido${NC}"
fi

if is_installed yay; then
    echo "   Removendo Yay..."
    sudo pacman -Rns yay --noconfirm || true
    echo -e "   ${VERDE}✓ Yay removido${NC}"
fi
echo ""

# 2. Remover Chaotic AUR
echo -e "${AZUL}2. Removendo Chaotic AUR...${NC}"
if grep -q "chaotic-aur" /etc/pacman.conf; then
    echo "   Removendo entrada Chaotic AUR de /etc/pacman.conf..."
    sudo sed -i '/\[chaotic-aur\]/,/^$/d' /etc/pacman.conf
    sudo sed -i '/chaotic-mirrorlist/d' /etc/pacman.conf
    
    # Remover chaves e pacotes do Chaotic
    sudo pacman-key --delete 3056513887B78AEB 2>/dev/null || true
    sudo pacman -Rns chaotic-keyring chaotic-mirrorlist 2>/dev/null || true
    
    sudo pacman -Sy --noconfirm
    echo -e "   ${VERDE}✓ Chaotic AUR removido${NC}"
else
    echo -e "   ℹ️  Chaotic AUR não encontrado"
fi
echo ""

# 3. Restaurar pacman.conf se backup existir
echo -e "${AZUL}3. Restaurando pacman.conf...${NC}"
if [ -f "/etc/pacman.conf.bak" ]; then
    echo "   Backup encontrado. Deseja restaurar de /etc/pacman.conf.bak? (y/n)"
    read -rp "Escolha: " restore_conf
    if [[ "$restore_conf" =~ ^[yY]$ ]]; then
        sudo mv /etc/pacman.conf.bak /etc/pacman.conf
        echo -e "   ${VERDE}✓ pacman.conf restaurado${NC}"
    else
        echo "   ℹ️  Backup mantido em /etc/pacman.conf.bak"
    fi
else
    echo -e "   ℹ️  Nenhum backup de pacman.conf encontrado"
fi
echo ""

# 4. Remover Pamac
echo -e "${AZUL}4. Removendo Pamac...${NC}"
if is_installed pamac; then
    echo "   Removendo Pamac..."
    sudo pacman -Rns pamac-all pamac-aur --noconfirm 2>/dev/null || true
    echo -e "   ${VERDE}✓ Pamac removido${NC}"
else
    echo -e "   ℹ️  Pamac não está instalado"
fi
echo ""

# 5. Remover Apps e Temas Essenciais
echo -e "${AZUL}5. Removendo apps e temas essenciais...${NC}"
EXTRA_PKGS=(
    "cursor-fluent"
    "fluent-cursor-theme"
    "gnome-themes-extra"
    "code"
    "visual-studio-code-bin"
    "papirus-icon-theme"
    "gdm-settings"
    "plymouth"
)
REMOVED_EXTRA=false
for pkg in "${EXTRA_PKGS[@]}"; do
    if is_pkg_installed "$pkg"; then
        echo "   Removendo $pkg..."
        sudo pacman -Rns "$pkg" --noconfirm 2>/dev/null || true
        REMOVED_EXTRA=true
    fi
done
if [[ "$REMOVED_EXTRA" == true ]]; then
    echo -e "   ${VERDE}✓ Apps e temas essenciais removidos${NC}"
else
    echo -e "   ℹ️  Nenhum app/tema essencial instalado"
fi
echo ""

# 6. Remover Flatpak
echo -e "${AZUL}6. Removendo Flatpak e aplicativos...${NC}"
if is_installed flatpak; then
    echo "   Removendo Flatpak..."
    flatpak uninstall --all -y 2>/dev/null || true
    sudo pacman -Rns flatpak --noconfirm || true
    echo -e "   ${VERDE}✓ Flatpak removido${NC}"
else
    echo -e "   ℹ️  Flatpak não está instalado"
fi
echo ""

# 7. Remover marcador do LinuxToys
echo -e "${AZUL}7. Limpando marcadores...${NC}"
MARKER_FILE="$HOME/.config/linuxtoys_installed.marker"
if [ -f "$MARKER_FILE" ]; then
    rm "$MARKER_FILE"
    echo -e "   ${VERDE}✓ Marcador LinuxToys removido${NC}"
fi
echo ""

# 8. Remover configuração de DNS
echo -e "${AZUL}8. Removendo configuração de DNS...${NC}"
if [ -f "/etc/NetworkManager/conf.d/99-dns-provider.conf" ]; then
    echo "   Removendo configuração de DNS..."
    sudo rm /etc/NetworkManager/conf.d/99-dns-provider.conf
    sudo systemctl restart NetworkManager
    echo -e "   ${VERDE}✓ Configuração de DNS removida${NC}"
else
    echo -e "   ℹ️  Configuração de DNS não encontrada"
fi

# Remover lock do resolv.conf se existir
if [ -f "/etc/resolv.conf" ]; then
    if sudo lsattr /etc/resolv.conf 2>/dev/null | grep -q "i"; then
        echo "   Removendo travamento de /etc/resolv.conf..."
        sudo chattr -i /etc/resolv.conf
        echo -e "   ${VERDE}✓ Travamento removido${NC}"
    fi
fi

# Restaurar backup do resolv.conf, se existir
if [ -f "/etc/resolv.conf.wellarch.bak" ]; then
    echo "   Restaurando backup do resolv.conf..."
    sudo mv /etc/resolv.conf.wellarch.bak /etc/resolv.conf
    sudo systemctl restart NetworkManager
    echo -e "   ${VERDE}✓ resolv.conf restaurado${NC}"
fi
echo ""

# 9. Limpeza final
echo -e "${AZUL}9. Limpeza final...${NC}"
echo "   Atualizando repositórios..."
sudo pacman -Sy --noconfirm > /dev/null
echo -e "   ${VERDE}✓ Repositórios atualizados${NC}"

# Remover diretório de configuração WELLARCH
if [ -d "${HOME}/.config/wellarch" ]; then
    read -rp "   Remover configurações do WELLARCH em ~/.config/wellarch? (y/n): " remove_config
    if [[ "$remove_config" =~ ^[yY]$ ]]; then
        rm -rf "${HOME}/.config/wellarch"
        echo -e "   ${VERDE}✓ Configurações removidas${NC}"
    fi
fi

# Remover cache do WELLARCH
if [ -d "${HOME}/.cache/wellarch" ]; then
    read -rp "   Remover cache do WELLARCH em ~/.cache/wellarch? (y/n): " remove_cache
    if [[ "$remove_cache" =~ ^[yY]$ ]]; then
        rm -rf "${HOME}/.cache/wellarch"
        echo -e "   ${VERDE}✓ Cache removido${NC}"
    fi
fi
echo ""

log_to_file "=== WELLARCH REMOVER v${VERSION} finalizado ==="

# ==============================================================================
# RESUMO FINAL
# ==============================================================================
echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✓ REMOÇÃO COMPLETA${NC}"
echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${AMARELO}📝 RESUMO:${NC}"
echo "   • AUR Helper removido"
echo "   • Chaotic AUR removido"
echo "   • Pamac removido"
echo "   • Apps/temas essenciais removidos (incluindo Plymouth)"
echo "   • Flatpak e aplicativos removidos"
echo "   • Configurações de DNS removidas"
echo ""
echo -e "${AMARELO}ℹ️  NOTAS:${NC}"
echo "   • Pacotes dependentes podem ter sido removidos"
echo "   • Arquivos pessoais criados pelos apps foram preservados"
echo "   • Backup de pacman.conf mantido em /etc/pacman.conf.bak se existir"
echo "   • Log disponível em: $LOGFILE"
echo ""

exit 0