#!/bin/bash

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

echo "🔑 Digite sua senha sudo para liberar as verificações:"
sudo -v
if [ $? -ne 0 ]; then parar_com_erro "Sudo recusado"; fi

# Mantém sudo vivo
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ---------------------------------------------------------
# 2. PARU (AUR HELPER)
# ---------------------------------------------------------
if is_installed paru; then
    echo "✅ Paru já está instalado. Pulando."
else
    echo "📦 Instalando Paru (Compilando do código fonte)..."
    sudo pacman -S --needed base-devel git --noconfirm
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    status=$?
    cd ..
    rm -rf paru
    if [ $status -ne 0 ]; then parar_com_erro "Instalação do Paru"; fi
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
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    sudo pacman -Sy --noconfirm
    if [ $? -ne 0 ]; then parar_com_erro "Chaotic AUR"; fi
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
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
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
        flatpak install flathub "$APP" -y
        if [ $? -ne 0 ]; then
            echo -e "   ${AMARELO}⚠️  Erro. Reparando e tentando novamente...${NC}"
            sudo flatpak repair
            flatpak install flathub "$APP" -y
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
    paru -S pamac-all --noconfirm
    if [ $? -ne 0 ]; then parar_com_erro "Instalação do Pamac-all"; fi
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
    sudo pacman -S --needed "${DEPS[@]}" --noconfirm
    curl -fsSL https://linux.toys/install.sh | bash
    if [ $? -eq 0 ]; then
        touch "$MARKER_FILE"
        echo -e "${VERDE}✅ LinuxToys instalado e marcador criado!${NC}"
    else
        echo -e "${VERMELHO}⚠️ Falha no LinuxToys.${NC}"
    fi
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
    sudo mkdir -p /etc/NetworkManager/conf.d/
    
    # 2. Cria arquivo de configuração global (Isso força o NetworkManager a usar estes IPs)
    # A sintaxe [global-dns-domain-*] aplica para todos os domínios
    sudo tee "$NM_CONF" > /dev/null <<EOF
[main]
dns=default

[global-dns-domain-*]
servers=1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001
EOF
    echo "   📄 Configuração do NetworkManager criada."

    # 3. Trava o resolv.conf clássico como backup (Cinto e suspensórios)
    RESOLV_CONF="/etc/resolv.conf"
    if lsattr "$RESOLV_CONF" 2>/dev/null | grep -q "i"; then sudo chattr -i "$RESOLV_CONF"; fi
    sudo rm -f "$RESOLV_CONF"
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 2606:4700:4700::1111\nnameserver 2606:4700:4700::1001\n" | sudo tee "$RESOLV_CONF" > /dev/null
    sudo chattr +i "$RESOLV_CONF"
    echo "   🔒 Arquivo resolv.conf travado manualmente."

    # 4. Reinicia o NetworkManager para aplicar
    echo "   🔄 Reiniciando serviço de rede..."
    sudo systemctl restart NetworkManager
    
    echo -e "${VERDE}✅ DNS Cloudflare IPv4 e IPv6 aplicado nativamente!${NC}"
fi

# ---------------------------------------------------------
# 9. LIMPEZA
# ---------------------------------------------------------
echo ""
echo -e "${AZUL}🧹 Limpeza do Sistema...${NC}"

sudo pacman -S --needed pacman-contrib --noconfirm &> /dev/null

echo "   📦 Limpando cache do Pacman..."
sudo paccache -rk 1 > /dev/null 2>&1
sudo pacman -Sc --noconfirm > /dev/null 2>&1

ORPHANS=$(pacman -Qdtq)
if [ -n "$ORPHANS" ]; then
    echo "   🗑️  Removendo órfãos..."
    sudo pacman -Rns $ORPHANS --noconfirm
    echo -e "   ${VERDE}✅ Órfãos removidos.${NC}"
else
    echo "   ✅ Nenhum órfão encontrado."
fi

echo "   🦄 Limpando cache do Paru..."
paru -c --noconfirm
paru -Sc --noconfirm

echo "   📱 Limpando Flatpaks..."
flatpak uninstall --unused -y > /dev/null 2>&1

echo "   📜 Limpando logs..."
sudo journalctl --vacuum-time=7d > /dev/null 2>&1

echo ""
echo -e "${VERDE}✨🎉 SETUP COMPLETO! SISTEMA OTIMIZADO. 🎉✨${NC}"