#!/bin/bash

# Safer bash defaults
set -euo pipefail
set -o errtrace
IFS=$'\n\t'

# Log tudo para arquivo (sem redirecionar stdout para evitar problemas de exibição)
LOGFILE="$HOME/.cache/wellarch/wellarch.log"
mkdir -p "$(dirname "$LOGFILE")"

# Função para gravar log com timestamp
log_to_file() {
	echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $*" >> "$LOGFILE"
}

# ==============================================================================
# DEFINIÇÃO DE CORES
# ==============================================================================
VERDE='\033[0;32m'
VERMELHO='\033[0;31m'
AMARELO='\033[1;33m'
AZUL='\033[0;36m' # Ciano
ROXO='\033[0;35m'
NC='\033[0m' # Sem cor

# Desativa cores em ambientes não interativos para evitar saída "estranha"
if [ ! -t 1 ]; then
	VERDE=''
	VERMELHO=''
	AMARELO=''
	AZUL=''
	ROXO=''
	NC=''
fi

# Versão do script (Semantic Versioning)
VERSION="15.0.0"

# Contadores de progresso
TOTAL_STEPS=9
CURRENT_STEP=0

# Função para mostrar progresso
show_progress() {
	local step_name="$1"
	CURRENT_STEP=$((CURRENT_STEP + 1))
	echo ""
	echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	echo -e "${ROXO}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${VERDE}${step_name}${NC}"
	echo -e "${AZUL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	log_to_file "[${CURRENT_STEP}/${TOTAL_STEPS}] ${step_name}"
}

# Logging helpers
VERBOSE=false
log_debug() { [ "$VERBOSE" = true ] && echo -e "${AZUL}[DEBUG]${NC} $*"; }
log_info() { echo -e "${AZUL}$*${NC}"; }
log_warn() { echo -e "${AMARELO}$*${NC}"; }
log_error() { echo -e "${VERMELHO}$*${NC}"; }

# ==============================================================================
# FUNÇÕES AUXILIARES
# ==============================================================================
is_installed() {
	command -v "$1" &>/dev/null || return 1
}

on_err() {
	# Recebe opcionalmente linha e exit code (passados pela trap). Caso contrário usa BASH_LINENO
	local line=${1:-${BASH_LINENO[0]:-?}}
	local exit_code=${2:-$?}
	echo -e "${VERMELHO}❌ Erro na linha ${line} (exit ${exit_code}).${NC}" >&2
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
	if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
		kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
	fi
	# remove temporary dirs safely
	for d in "${TMP_DIRS[@]:-}"; do
		if [[ -n "$d" && "$d" = /* && -e "$d" ]]; then
			rm -rf -- "$d" || true
		fi
	done
}
trap 'on_err ${LINENO} $?' ERR
trap cleanup EXIT INT TERM

# Inicia um keepalive do sudo em background; guarda PID para cleanup
start_sudo_keepalive() {
	# não inicia se já estiver rodando
	if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
		return 0
	fi
	(
		while true; do
			sudo -v 2>/dev/null || break
			sleep 60
		done
	) &
	SUDO_KEEPALIVE_PID=$!
}

# Helper to run commands and fail with message
run_cmd() {
	if [ "${DRY_RUN:-false}" = true ]; then
		echo -e "${AMARELO}(dry-run) CMD:${NC} $*"
		return 0
	fi
	if ! "$@"; then
		parar_com_erro "Comando falhou: $*"
	fi
}

# sudo wrapper (mantém compatibilidade caso já estejamos em root)
sudo_run() {
	if [ "$EUID" -eq 0 ]; then
		run_cmd "$@"
	else
		run_cmd sudo "$@"
	fi
}

# Verifica conectividade com internet
check_internet() {
	if ! ping -c 1 8.8.8.8 &>/dev/null && ! ping -c 1 1.1.1.1 &>/dev/null; then
		parar_com_erro "Sem conexão com internet. Verifique sua conexão de rede."
	fi
}

# Verifica espaço em disco
check_disk_space() {
	local available
	available=$(df "$HOME" | tail -1 | awk '{print $4}')
	local required=$((3 * 1024 * 1024)) # 3GB em KB
	if [[ "$available" -lt "$required" ]]; then
		echo -e "${AMARELO}⚠️  AVISO: Apenas $(numfmt --to=iec-i --suffix=B $((available * 1024))) disponíveis.${NC}"
		echo -e "${AMARELO}Recomendado: 3GB ou mais para Flatpaks e outras aplicações.${NC}"
		if [ "$ASSUME_YES" = true ]; then
			log_warn "Continuando (ASSUME_YES ativo)."
		else
			read -r -p "Deseja continuar mesmo assim? (y/n): " cont_space
			if [[ ! "$cont_space" =~ ^[yY]$ ]]; then
				echo -e "${VERMELHO}Operação cancelada.${NC}"
				exit 0
			fi
		fi
	fi
}

# Salvar IFS original para restaurar depois
ORIGINAL_IFS="$IFS"

# Inicializa arrays para rastrear instalações
INSTALLED_PACKAGES=()
INSTALLED_FLATPAKS=()
FAILED_ITEMS=()

# Argumentos e flags de skip
DRY_RUN=false
ASSUME_YES=false
FORCE_RESOLV_LOCK=false
SKIP_UPDATE=false
SKIP_MIRRORS=false
SKIP_CHAOTIC=false
SKIP_FLATPAK=false
SKIP_PAMAC=false
SKIP_DNS=false
SKIP_LINUXTOYS=false
SKIP_CLEANUP=false
while [ $# -gt 0 ]; do
	case "${1-}" in
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--yes | -y)
		ASSUME_YES=true
		shift
		;;
	--verbose)
		VERBOSE=true
		shift
		;;
	--version)
		echo -e "WELLARCH v${VERSION}"
		exit 0
		;;
	--force-resolv-lock)
		FORCE_RESOLV_LOCK=true
		shift
		;;
	--skip-update)
		SKIP_UPDATE=true
		shift
		;;
	--skip-mirrors)
		SKIP_MIRRORS=true
		shift
		;;
	--skip-chaotic)
		SKIP_CHAOTIC=true
		shift
		;;
	--skip-flatpak)
		SKIP_FLATPAK=true
		shift
		;;
	--skip-pamac)
		SKIP_PAMAC=true
		shift
		;;
	--skip-dns)
		SKIP_DNS=true
		shift
		;;
	--skip-linuxtoys)
		SKIP_LINUXTOYS=true
		shift
		;;
	--skip-cleanup)
		SKIP_CLEANUP=true
		shift
		;;
	--help | -h)
		cat <<EOF
${AZUL}WELLARCH v${VERSION} - Automação para Arch Linux${NC}

${AMARELO}USO:${NC}
  $0 [OPÇÕES]

${AMARELO}OPÇÕES GERAIS:${NC}
  --dry-run              Simula execução sem fazer alterações
  --verbose              Ativa mensagens de debug
  --version              Exibe versão do script
  --yes, -y              Assume "sim" para todos os prompts
  --force-resolv-lock    Trava /etc/resolv.conf com chattr +i
  --help, -h             Exibe este menu de ajuda

${AMARELO}OPÇÕES DE SKIP (pular etapas):${NC}
  --skip-update          Pula atualização do sistema (pacman -Syu)
  --skip-mirrors         Pula otimização de mirrors (reflector)
  --skip-chaotic         Pula configuração do Chaotic AUR
  --skip-flatpak         Pula instalação de Flatpak e apps
  --skip-pamac           Pula instalação do Pamac
  --skip-dns             Pula configuração de DNS
  --skip-linuxtoys       Pula instalação do LinuxToys
  --skip-cleanup         Pula limpeza do sistema

${AMARELO}EXEMPLOS:${NC}
  # Executar normalmente:
  $0

  # Modo automático:
  $0 --yes

  # Pular DNS e Flatpak:
  $0 --skip-dns --skip-flatpak

  # Simular execução:
  $0 --dry-run --yes

${AMARELO}DESINSTALAÇÃO:${NC}
  ./wellarch-remove.sh
EOF
		exit 0
		;;
	*) break ;;
	esac
done

# ==============================================================================
# PREPARAÇÃO VISUAL
# ==============================================================================
clear
echo -e "${AZUL}"
cat <<"EOF"
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║   ██╗    ██╗███████╗██╗     ██╗      █████╗ ██████╗  ██████╗██╗  ██╗      ║
║   ██║    ██║██╔════╝██║     ██║     ██╔══██╗██╔══██╗██╔════╝██║  ██║      ║
║   ██║ █╗ ██║█████╗  ██║     ██║     ███████║██████╔╝██║     ███████║      ║
║   ██║███╗██║██╔══╝  ██║     ██║     ██╔══██║██╔══██╗██║     ██╔══██║      ║
║   ╚███╔███╔╝███████╗███████╗███████╗██║  ██║██║  ██║╚██████╗██║  ██║      ║
║    ╚══╝╚══╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝      ║ 
║                                                                           ║
║              Automação, Pós-Instalação e Otimização                       ║
║                        para Arch Linux v15.0                            ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
echo -e "${ROXO}👤 Desenvolvido para: ${AMARELO}Wesley${NC}"
echo -e "${ROXO}📦 Gerenciador de instalação e otimização do sistema${NC}"
echo -e "═══════════════════════════════════════════════════════════"
echo -e "📝 ${VERDE}RESUMO DO QUE SERÁ FEITO:${NC}"
echo -e "   1. Validação do Sistema"
echo -e "   2. AUR Helper & Chaotic AUR"
echo -e "   3. Flatpak & Flathub"
echo -e "   4. Aplicativos Flatpak"
echo -e "   5. Gerenciador Pamac"
echo -e "   6. LinuxToys"
echo -e "   7. Configuração de DNS"
echo -e "   8. Limpeza do Sistema"
echo -e "-------------------------------------------------------------"
echo ""

if [[ "$ASSUME_YES" == true ]]; then
	confirm='y'
else
	read -r -p "Deseja executar esse script? (y/n): " confirm
fi
if [[ ! "$confirm" =~ ^[yY]$ ]]; then
	echo -e "${VERMELHO}❌ Operação cancelada.${NC}"
	exit 0
fi

# ==============================================================================
# MENU DE CONFIGURAÇÕES
# ==============================================================================

echo ""
echo -e "${AZUL}⚙️  CONFIGURAÇÕES PRÉ-INSTALAÇÃO${NC}"
echo "-------------------------------------------------------------"

# Menu para escolher AUR Helper (com cores)
echo ""
echo -e "${AMARELO}1. Qual AUR Helper você deseja?${NC}"
echo -e "   ${VERDE}a)${NC} Paru (padrão, mais rápido)"
echo -e "   ${VERDE}b)${NC} Yay (alternativa)"
if [[ "$ASSUME_YES" == true ]]; then
	aur_choice='a'
else
	read -r -p "Escolha (a/b) [a]: " aur_choice
	aur_choice="${aur_choice:-a}"
fi
case "${aur_choice,,}" in
b | yay)
	AUR_HELPER="yay"
	echo -e "${VERDE}✓ Escolhido: Yay${NC}"
	;;
a | paru | *)
	AUR_HELPER="paru"
	echo -e "${VERDE}✓ Escolhido: Paru${NC}"
	;;
esac

# Menu para escolher Pamac (com cores)
echo ""
echo -e "${AMARELO}2. Qual versão do Pamac você deseja?${NC}"
echo -e "   ${VERDE}a)${NC} Pamac-all (com GUI + Flatpak + AUR, padrão)"
echo -e "   ${VERDE}b)${NC} Pamac-aur (apenas CLI + AUR)"
if [[ "$ASSUME_YES" == true ]]; then
	pamac_choice='a'
else
	read -r -p "Escolha (a/b) [a]: " pamac_choice
	pamac_choice="${pamac_choice:-a}"
fi
case "${pamac_choice,,}" in
b | aur)
	PAMAC_PKG="pamac-aur"
	echo -e "${VERDE}✓ Escolhido: Pamac-aur${NC}"
	;;
a | all | *)
	PAMAC_PKG="pamac-all"
	echo -e "${VERDE}✓ Escolhido: Pamac-all${NC}"
	;;
esac

# Menu para escolher DNS (com cores)
echo ""
echo -e "${AMARELO}3. Qual provedor de DNS você deseja?${NC}"
echo -e "   ${VERDE}a)${NC} Cloudflare (padrão, 1.1.1.1) - Privacidade"
echo -e "   ${VERDE}b)${NC} Quad9 (9.9.9.9) - Segurança"
echo -e "   ${VERDE}c)${NC} Google (8.8.8.8) - Velocidade"
echo -e "   ${VERDE}d)${NC} AdGuard (94.140.14.14) - Bloqueia anúncios"
echo -e "   ${VERDE}e)${NC} Manter padrão do sistema (sem alterações)"
if [[ "$ASSUME_YES" == true ]]; then
	dns_choice='a'
else
	read -r -p "Escolha (a/b/c/d/e) [a]: " dns_choice
	dns_choice="${dns_choice:-a}"
fi
case "${dns_choice,,}" in
b | quad9)
	DNS_PROVIDER="quad9"
	DNS_SERVERS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
	echo -e "${VERDE}✓ Escolhido: Quad9${NC}"
	;;
c | google)
	DNS_PROVIDER="google"
	DNS_SERVERS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
	echo -e "${VERDE}✓ Escolhido: Google DNS${NC}"
	;;
d | adguard)
	DNS_PROVIDER="adguard"
	DNS_SERVERS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
	echo -e "${VERDE}✓ Escolhido: AdGuard DNS${NC}"
	;;
e | none | skip)
	DNS_PROVIDER="none"
	DNS_SERVERS=""
	echo -e "${VERDE}✓ Escolhido: Manter padrão do sistema${NC}"
	;;
a | cloudflare | *)
	DNS_PROVIDER="cloudflare"
	DNS_SERVERS="1.1.1.1,1.0.0.1,2606:4700:4700::1111,2606:4700:4700::1001"
	echo -e "${VERDE}✓ Escolhido: Cloudflare${NC}"
	;;
esac

# Menu para selecionar apps Flatpak
echo ""
echo -e "${AMARELO}4. Selecione os aplicativos Flatpak a instalar:${NC}"
AVAILABLE_APPS=(
	"com.rtosta.zapzap:ZapZap (WhatsApp)"
	"org.telegram.desktop:Telegram"
	"com.vysp3r.ProtonPlus:ProtonPlus"
	"org.equicord.equibop:Equibop"
	"com.github.wwmm.easyeffects:Easy Effects"
	"io.github.flattool.Ignition:Ignition"
	"com.brave.Browser:Brave Browser"
	"com.mattjakeman.ExtensionManager:GNOME Extension Manager"
)

SELECTED_APPS=()
for app_info in "${AVAILABLE_APPS[@]}"; do
	app_id="${app_info%%:*}"
	app_name="${app_info##*:}"
	if [[ "$ASSUME_YES" == true ]]; then
		SELECTED_APPS+=("$app_id")
	else
		read -r -p "Instalar $app_name? (y/n) [y]: " install_app
		install_app="${install_app:-y}"
		if [[ "$install_app" =~ ^[yY]$ ]]; then
			SELECTED_APPS+=("$app_id")
		fi
	fi
done

if [ ${#SELECTED_APPS[@]} -eq 0 ]; then
	echo -e "${AMARELO}⚠️  Nenhum app Flatpak selecionado.${NC}"
else
	echo -e "${VERDE}✓ ${#SELECTED_APPS[@]} aplicativo(s) selecionado(s)${NC}"
fi

echo ""
echo -e "${AZUL}Configurações confirmadas!${NC}"
echo "-------------------------------------------------------------"

# ==============================================================================
# RESUMO DAS CONFIGURAÇÕES ANTES DE EXECUTAR
# ==============================================================================
echo ""
echo -e "${ROXO}╔═════════════════════════════════════════════════════════╗${NC}"
echo -e "${ROXO}║${NC}   ${AMARELO}📝 RESUMO DAS CONFIGURAÇÕES${NC}                          ${ROXO}║${NC}"
echo -e "${ROXO}╠═════════════════════════════════════════════════════════╣${NC}"
echo -e "${ROXO}║${NC}   AUR Helper:     ${VERDE}${AUR_HELPER}${NC}"
echo -e "${ROXO}║${NC}   Pamac:          ${VERDE}${PAMAC_PKG}${NC}"
echo -e "${ROXO}║${NC}   DNS:            ${VERDE}${DNS_PROVIDER}${NC}"
echo -e "${ROXO}║${NC}   Flatpaks:       ${VERDE}${#SELECTED_APPS[@]} selecionado(s)${NC}"
echo -e "${ROXO}║${NC}   Dry-run:        ${VERDE}${DRY_RUN}${NC}"
echo -e "${ROXO}╚═════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ "$ASSUME_YES" != true ]]; then
	read -r -p "Confirmar e iniciar instalação? (y/n): " final_confirm
	if [[ ! "$final_confirm" =~ ^[yY]$ ]]; then
		echo -e "${VERMELHO}❌ Operação cancelada.${NC}"
		exit 0
	fi
fi

# Registrar início no log
START_TIME=$(date +%s)
log_to_file "=== WELLARCH v${VERSION} iniciado ==="
log_to_file "Configurações: AUR=${AUR_HELPER} PAMAC=${PAMAC_PKG} DNS=${DNS_PROVIDER} FLATPAKS=${#SELECTED_APPS[@]}"

# ==============================================================================
# INÍCIO DA EXECUÇÃO
# ==============================================================================

echo ""
echo -e "${AMARELO}🚀 Iniciando WELLARCH v${VERSION}...${NC}"

# 1. Checagem de Root
if [ "$EUID" -eq 0 ]; then
	echo -e "${VERMELHO}⚠️  Não rode como root. Use ./script.sh (o script pedirá a senha).${NC}"
	exit 1
fi

# Verifica se é Arch Linux
if ! grep -qi "arch" /etc/os-release; then
	echo -e "${VERMELHO}⚠️ Este script foi feito para Arch Linux. Saindo.${NC}"
	exit 1
fi

log_info "🔑 Validando permissões sudo..."
if ! sudo -v; then
	parar_com_erro "Acesso sudo recusado. Você precisa de privilégios sudo."
fi

# Verifica conectividade
echo "🌐 Verificando conectividade com internet..."
check_internet

# Verifica espaço em disco
echo "💾 Verificando espaço em disco..."
check_disk_space

# Mantém sudo vivo (background) e guarda PID para cleanup
start_sudo_keepalive

# ---------------------------------------------------------
# 1. ATUALIZAÇÃO DO SISTEMA (pacman -Syu)
# ---------------------------------------------------------
update_system() {
	show_progress "Atualização do Sistema"
	
	if [[ "$SKIP_UPDATE" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando atualização do sistema (--skip-update)${NC}"
		return 0
	fi
	
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo -e "${AMARELO}(dry-run) pulando pacman -Syu${NC}"
		return 0
	fi
	
	echo "🔄 Atualizando sistema com pacman -Syu..."
	if sudo_run pacman -Syu --noconfirm; then
		echo -e "${VERDE}✅ Sistema atualizado!${NC}"
		INSTALLED_PACKAGES+=("System Update")
	else
		echo -e "${AMARELO}⚠️  Aviso durante atualização do sistema.${NC}"
	fi
}

update_system

# ---------------------------------------------------------
# 2. Atualizar mirrorlist com reflector (rápido e recomendado)
# ---------------------------------------------------------
setup_reflector() {
	show_progress "Otimização de Mirrors"
	
	if [[ "$SKIP_MIRRORS" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando otimização de mirrors (--skip-mirrors)${NC}"
		return 0
	fi
	
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo -e "${AMARELO}(dry-run) pulando atualização de mirrors com reflector${NC}"
		return 0
	fi

	if ! is_installed reflector; then
		echo "🔧 Instalando reflector para ordenação de mirrors..."
		sudo_run pacman -S --needed reflector --noconfirm || {
			echo -e "${AMARELO}⚠️ Não foi possível instalar reflector automaticamente.${NC}"
			return 1
		}
	else
		echo "✅ reflector já instalado."
	fi

	if is_installed reflector; then
		echo "🔄 Atualizando /etc/pacman.d/mirrorlist priorizando Brasil..."
		sudo_run cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.wellarch.bak || true
		if ! sudo_run reflector --country Brazil --protocol https --latest 20 --sort rate --age 24 --save /etc/pacman.d/mirrorlist; then
			echo -e "${AMARELO}⚠️ Falha ao executar reflector com país Brasil; mantendo mirrorlist atual.${NC}"
			return 1
		fi
		sudo_run pacman -Syy --noconfirm || true
	fi
}

setup_reflector

# ---------------------------------------------------------
# 3. CHAOTIC AUR
# ---------------------------------------------------------
setup_chaotic_aur() {
	show_progress "Configuração do Chaotic AUR"
	
	if [[ "$SKIP_CHAOTIC" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando Chaotic AUR (--skip-chaotic)${NC}"
		return 0
	fi
	
	if grep -q "chaotic-aur" /etc/pacman.conf; then
		echo "✅ Chaotic AUR já está configurado. Pulando."
		return 0
	fi
	echo "🌀 Configurando Chaotic AUR..."
	sudo_run cp /etc/pacman.conf /etc/pacman.conf.bak
	echo "   📝 Backup de /etc/pacman.conf criado em /etc/pacman.conf.bak"

	sudo_run pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	sudo_run pacman-key --lsign-key 3056513887B78AEB
	sudo_run pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
		'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
	echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo_run tee -a /etc/pacman.conf >/dev/null
	sudo_run pacman -Sy --noconfirm
	echo -e "${VERDE}✅ Chaotic AUR configurado!${NC}"
	INSTALLED_PACKAGES+=("Chaotic AUR")
}

setup_chaotic_aur

# ---------------------------------------------------------
# 4. AUR HELPER (PARU OU YAY)
# ---------------------------------------------------------
install_aur_helper() {
	show_progress "Instalação do AUR Helper"
	
	if is_installed "$AUR_HELPER"; then
		echo "✅ $AUR_HELPER já está instalado. Pulando."
		return 0
	fi
	echo "📦 Instalando $AUR_HELPER..."

	if sudo pacman -S "$AUR_HELPER" --noconfirm 2>/dev/null; then
		echo -e "${VERDE}✅ $AUR_HELPER instalado via repositório!${NC}"
		INSTALLED_PACKAGES+=("$AUR_HELPER")
		return 0
	fi

	echo "📦 Instalando $AUR_HELPER-bin do AUR..."
	sudo_run pacman -S --needed base-devel git --noconfirm
	local tmpdir
	tmpdir=$(mktemp -d)
	TMP_DIRS+=("$tmpdir")

	run_cmd git clone "https://aur.archlinux.org/${AUR_HELPER}-bin.git" "$tmpdir/$AUR_HELPER"
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

install_aur_helper

# ---------------------------------------------------------
# 5. FLATPAK & FLATHUB
# ---------------------------------------------------------
setup_flatpak() {
	show_progress "Configuração do Flatpak"
	
	if [[ "$SKIP_FLATPAK" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando Flatpak (--skip-flatpak)${NC}"
		return 0
	fi
	
	if ! is_installed flatpak; then
		echo "📦 Instalando Flatpak..."
		sudo_run pacman -S flatpak --noconfirm
		INSTALLED_PACKAGES+=("Flatpak")
	else
		echo "✅ Flatpak já está instalado."
	fi

	if ! flatpak remote-list 2>/dev/null | grep -q "flathub"; then
		echo "🌐 Adicionando Flathub..."
		run_cmd flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
		echo -e "${VERDE}✅ Flathub configurado!${NC}"
	else
		echo "✅ Repositório Flathub já ativo. Pulando."
	fi
}

setup_flatpak

# ---------------------------------------------------------
# 6. APPS FLATPAK
# ---------------------------------------------------------
show_progress "Instalação de Apps Flatpak"

if [[ "$SKIP_FLATPAK" == true ]]; then
	echo -e "${AMARELO}⏭️  Pulando apps Flatpak (--skip-flatpak)${NC}"
elif [[ ${#SELECTED_APPS[@]} -gt 0 ]]; then
echo "📱 Instalando aplicativos Flatpak selecionados..."
for APP in "${SELECTED_APPS[@]}"; do
	if flatpak list --app | grep -q "$APP"; then
		echo -e "   ℹ️  $APP já instalado. Pulando."
	else
		echo -e "   ⬇️  Instalando $APP..."
		if [[ "$DRY_RUN" == true ]]; then
			echo "   (dry-run) pulando instalação de $APP"
		else
			if flatpak install flathub "$APP" -y; then
				INSTALLED_FLATPAKS+=("$APP")
			else
				echo -e "   ${AMARELO}⚠️  Erro. Reparando e tentando novamente...${NC}"
				sudo_run flatpak repair || true
				if flatpak install flathub "$APP" -y; then
					INSTALLED_FLATPAKS+=("$APP")
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

# ---------------------------------------------------------
# 7. PAMAC (via AUR Helper)
# ---------------------------------------------------------
show_progress "Instalação do Pamac"

if [[ "$SKIP_PAMAC" == true ]]; then
	echo -e "${AMARELO}⏭️  Pulando Pamac (--skip-pamac)${NC}"
elif is_installed pamac; then
	echo "✅ Pamac já está instalado. Pulando."
else
	echo "🛍️  Instalando $PAMAC_PKG..."
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo "(dry-run) pulando instalação do $PAMAC_PKG"
	else
		if ! $AUR_HELPER -S "$PAMAC_PKG" --noconfirm; then
			parar_com_erro "Instalação do $PAMAC_PKG"
		fi
		INSTALLED_PACKAGES+=("Pamac")
	fi
	echo -e "${VERDE}✅ Pamac instalado!${NC}"
fi

# ---------------------------------------------------------
# 8. LINUXTOYS
# ---------------------------------------------------------
show_progress "Instalação do LinuxToys"

MARKER_FILE="$HOME/.config/linuxtoys_installed.marker"

if [[ "$SKIP_LINUXTOYS" == true ]]; then
	echo -e "${AMARELO}⏭️  Pulando LinuxToys (--skip-linuxtoys)${NC}"
elif [ -f "$MARKER_FILE" ]; then
	echo "✅ LinuxToys já foi executado. Pulando."
else
	echo "🧸 Instalando LinuxToys..."
	DEPS=(bash git curl wget zenity python python-gobject python-requests gtk3 vte3)
	sudo_run pacman -S --needed "${DEPS[@]}" --noconfirm

	lt_tmp=$(mktemp -d)
	TMP_DIRS+=("$lt_tmp")
	lt_script="$lt_tmp/linuxtoys-install.sh"
	if ! curl -fsSL -o "$lt_script" https://linux.toys/install.sh; then
		echo -e "${VERMELHO}⚠️ Falha ao baixar LinuxToys.${NC}"
		FAILED_ITEMS+=("LinuxToys")
	else
		echo "Script LinuxToys salvo em: $lt_script"
		LT_OK=false
		if [[ "${DRY_RUN:-false}" == true ]]; then
			echo -e "${AMARELO}(dry-run) não executando instalador do LinuxToys${NC}"
		else
			if [[ "$ASSUME_YES" == true ]]; then
				if bash "$lt_script"; then
					LT_OK=true
				fi
			else
				read -r -p "Executar o instalador do LinuxToys agora? (y/n): " anslt
				if [[ "$anslt" =~ ^[yY]$ ]]; then
					if bash "$lt_script"; then
						LT_OK=true
					fi
				else
					echo "Pulando execução do instalador LinuxToys (arquivo baixado)."
				fi
			fi
		fi
		if [ "$LT_OK" = true ]; then
			touch "$MARKER_FILE"
			echo -e "${VERDE}✅ LinuxToys instalado e marcador criado!${NC}"
			INSTALLED_PACKAGES+=("LinuxToys")
		else
			echo -e "${VERMELHO}⚠️ Falha no LinuxToys.${NC}"
			FAILED_ITEMS+=("LinuxToys")
		fi
	fi
	if [[ "$lt_tmp" = /* ]] && [ -d "$lt_tmp" ]; then
		rm -rf -- "$lt_tmp"
	fi
	TMP_DIRS=()
fi

# ---------------------------------------------------------
# 9. DNS (SOLUÇÃO DEFINITIVA NETWORK MANAGER)
# ---------------------------------------------------------
setup_dns() {
	show_progress "Configuração de DNS"
	
	if [[ "$SKIP_DNS" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando configuração de DNS (--skip-dns)${NC}"
		return 0
	fi
	
	if [[ "$DNS_PROVIDER" != "none" ]]; then
		echo "🌐 Configurando DNS..."
		NM_CONF="/etc/NetworkManager/conf.d/99-dns-provider.conf"

		# Sanity check: DNS_SERVERS deve estar definido
		if [[ -z "${DNS_SERVERS:-}" ]]; then
			echo -e "${AMARELO}⚠️ DNS_SERVERS vazio; pulando configuração de DNS.${NC}"
		else
			if [[ -f "$NM_CONF" ]]; then
				echo "✅ Configuração de DNS já aplicada. Pulando."
			else
				echo "⚙️  Aplicando DNS via NetworkManager..."

				# 1. Cria a pasta se não existir
				sudo_run mkdir -p /etc/NetworkManager/conf.d/

				# 2. Cria arquivo de configuração global
				sudo_run tee "$NM_CONF" >/dev/null <<EOF
[main]
dns=default

[global-dns-domain-*]
servers=$DNS_SERVERS
EOF
				echo "   📄 Configuração do NetworkManager criada para $DNS_PROVIDER."

				# 3. Atualiza resolv.conf localmente (sem travar por padrão)
				RESOLV_CONF="/etc/resolv.conf"
				sudo_run rm -f "$RESOLV_CONF" || true

				# Separa os servers em nameservers
				IFS=',' read -ra SERVERS <<<"$DNS_SERVERS"
				for server in "${SERVERS[@]}"; do
					printf "nameserver %s\n" "$server" | sudo_run tee -a "$RESOLV_CONF" >/dev/null
				done

				if [[ "$FORCE_RESOLV_LOCK" == true ]]; then
					echo "   🔒 Travando resolv.conf (opção forçada)."
					sudo_run chattr +i "$RESOLV_CONF"
				else
					echo "   ℹ️  resolv.conf atualizado. Use --force-resolv-lock para travar (não recomendado)."
				fi

				# 4. Reinicia o NetworkManager para aplicar
				echo "   🔄 Reiniciando serviço de rede..."
				sudo_run systemctl restart NetworkManager

				echo -e "${VERDE}✅ DNS configurado!${NC}"
				INSTALLED_PACKAGES+=("DNS: $DNS_PROVIDER")
			fi
		fi
	else
		echo "⏭️ DNS: Mantendo configuração padrão do sistema."
	fi
}

setup_dns

# Restaurar IFS original
IFS="$ORIGINAL_IFS"

# ---------------------------------------------------------
# 10. LIMPEZA
# ---------------------------------------------------------
show_progress "Limpeza do Sistema"

if [[ "$SKIP_CLEANUP" == true ]]; then
	echo -e "${AMARELO}⏭️  Pulando limpeza (--skip-cleanup)${NC}"
else

echo -e "${AZUL}🧹 Limpeza do Sistema...${NC}"

sudo_run pacman -S --needed pacman-contrib --noconfirm &>/dev/null

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
if ! $AUR_HELPER -c --noconfirm >/dev/null 2>&1; then
	echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do $AUR_HELPER (-c).${NC}"
fi
if ! $AUR_HELPER -Sc --noconfirm >/dev/null 2>&1; then
	echo -e "   ${AMARELO}⚠️  Aviso ao limpar cache do $AUR_HELPER (-Sc).${NC}"
fi

echo "   📱 Limpando Flatpaks..."
flatpak uninstall --unused -y >/dev/null 2>&1

echo "   📜 Limpando logs..."
sudo_run journalctl --vacuum-time=7d >/dev/null 2>&1

fi # Fim do bloco SKIP_CLEANUP

# ==============================================================================
# RELATÓRIO FINAL
# ==============================================================================

# Calcular tempo de execução
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_MIN=$((ELAPSED / 60))
ELAPSED_SEC=$((ELAPSED % 60))

echo ""
echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✨ RELATÓRIO FINAL DA INSTALAÇÃO ✨${NC}"
echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${AMARELO}⏱️  TEMPO DE EXECUÇÃO:${NC} ${ELAPSED_MIN}m ${ELAPSED_SEC}s"
echo ""

echo -e "${AMARELO}📋 CONFIGURAÇÕES SELECIONADAS:${NC}"
echo -e "   AUR Helper: ${VERDE}$AUR_HELPER${NC}"
echo -e "   Pamac: ${VERDE}$PAMAC_PKG${NC}"
echo -e "   DNS: ${VERDE}$DNS_PROVIDER${NC}"
echo ""

if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
	echo -e "${AMARELO}📦 PACOTES INSTALADOS: ${#INSTALLED_PACKAGES[@]}${NC}"
	for pkg in "${INSTALLED_PACKAGES[@]}"; do
		echo -e "   ${VERDE}✓${NC} $pkg"
	done
	echo ""
fi

if [[ ${#INSTALLED_FLATPAKS[@]} -gt 0 ]]; then
	echo -e "${AMARELO}📱 APLICATIVOS FLATPAK INSTALADOS: ${#INSTALLED_FLATPAKS[@]}${NC}"
	for flatpak_app in "${INSTALLED_FLATPAKS[@]}"; do
		echo -e "   ${VERDE}✓${NC} $flatpak_app"
	done
	echo ""
fi

if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
	echo -e "${AMARELO}❌ ITENS QUE FALHARAM: ${#FAILED_ITEMS[@]}${NC}"
	for failed in "${FAILED_ITEMS[@]}"; do
		echo -e "   ${VERMELHO}✗${NC} $failed"
	done
	echo ""
fi

echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✨🎉 SETUP COMPLETO! SISTEMA OTIMIZADO. 🎉✨${NC}"
echo -e "${AZUL}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${AMARELO}📝 LOG COMPLETO DISPONÍVEL EM:${NC} $LOGFILE"
echo ""

# Gravar fim no log
log_to_file "=== WELLARCH v${VERSION} finalizado em ${ELAPSED_MIN}m ${ELAPSED_SEC}s ==="
log_to_file "Pacotes instalados: ${#INSTALLED_PACKAGES[@]} | Flatpaks: ${#INSTALLED_FLATPAKS[@]} | Falhas: ${#FAILED_ITEMS[@]}"

# Notificação desktop (se disponível)
if is_installed notify-send; then
	notify-send -i dialog-information "WELLARCH v${VERSION}" "Setup completo em ${ELAPSED_MIN}m ${ELAPSED_SEC}s! ✨" 2>/dev/null || true
fi
