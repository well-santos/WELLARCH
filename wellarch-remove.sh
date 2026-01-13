#!/bin/bash

# Script para remover/desfazer alterações do WELLARCH
# Ativa modo seguro
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# DEFINIÇÃO DE CORES
# ==============================================================================
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;36m'
ROXO='\033[0;35m'
NC='\033[0m'

# Desativa cores em ambientes não interativos
if [ ! -t 1 ]; then
    VERDE=''
    VERMELHO=''
    AMARELO=''
    AZUL=''
    ROXO=''
    NC=''
fi

# ==============================================================================
# FUNÇÕES
# ==============================================================================
parar_com_erro() {
    echo -e "${VERMELHO}❌ ERRO: $1 ${NC}"
    exit 1
}

is_installed() {
    command -v "$1" &> /dev/null
}

# ==============================================================================
# VERIFICAÇÕES INICIAIS
# ==============================================================================
clear
echo -e "${AZUL}"
echo "WELLARCH REMOVER v15.0.0"
echo -e "${NC}"
echo -e "${ROXO}:: Script de Desinstalação para WELLARCH ::${NC}"
echo -e "-------------------------------------------------------------"
echo -e "${VERMELHO}⚠️  AVISO: Este script removerá alterações feitas pelo WELLARCH${NC}"
echo ""

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

# 5. Remover Flatpak
echo -e "${AZUL}5. Removendo Flatpak e aplicativos...${NC}"
if is_installed flatpak; then
    echo "   Removendo Flatpak..."
    flatpak uninstall --all -y 2>/dev/null || true
    sudo pacman -Rns flatpak --noconfirm || true
    echo -e "   ${VERDE}✓ Flatpak removido${NC}"
else
    echo -e "   ℹ️  Flatpak não está instalado"
fi
echo ""

# 6. Remover marcador do LinuxToys
echo -e "${AZUL}6. Limpando marcadores...${NC}"
MARKER_FILE="$HOME/.config/linuxtoys_installed.marker"
if [ -f "$MARKER_FILE" ]; then
    rm "$MARKER_FILE"
    echo -e "   ${VERDE}✓ Marcador LinuxToys removido${NC}"
fi
echo ""

# 7. Remover configuração de DNS
echo -e "${AZUL}7. Removendo configuração de DNS...${NC}"
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
echo ""

# 8. Limpeza final
echo -e "${AZUL}8. Limpeza final...${NC}"
echo "   Atualizando repositórios..."
sudo pacman -Sy --noconfirm > /dev/null
echo -e "   ${VERDE}✓ Repositórios atualizados${NC}"
echo ""

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
echo "   • Flatpak e aplicativos removidos"
echo "   • Configurações de DNS removidas"
echo ""
echo -e "${AMARELO}ℹ️  NOTAS:${NC}"
echo "   • Pacotes dependentes podem ter sido removidos"
echo "   • Arquivos pessoais criados pelos apps foram preservados"
echo "   • Backup de pacman.conf mantido em /etc/pacman.conf.bak se existir"
echo ""
