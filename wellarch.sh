#!/bin/bash
# ==============================================================================
# WELLARCH - Automação e Otimização para Arch Linux
# Version: 15.1.0
# ==============================================================================

# Safer bash defaults
set -euo pipefail
set -o errtrace
IFS=$'\n\t'

# Script directory for sourcing libraries
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
	SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source common library if available, otherwise use inline definitions
if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/lib/common.sh" ]]; then
    # shellcheck source=lib/common.sh
    source "${SCRIPT_DIR}/lib/common.sh"
    USING_COMMON_LIB=true

    for lib_file in \
        "${SCRIPT_DIR}/lib/menu.sh" \
        "${SCRIPT_DIR}/lib/safe_mode.sh" \
        "${SCRIPT_DIR}/lib/system.sh" \
        "${SCRIPT_DIR}/lib/steps.sh" \
        "${SCRIPT_DIR}/lib/aur.sh" \
        "${SCRIPT_DIR}/lib/mirrors.sh" \
        "${SCRIPT_DIR}/lib/flatpak.sh" \
        "${SCRIPT_DIR}/lib/packages.sh" \
        "${SCRIPT_DIR}/lib/dns.sh" \
        "${SCRIPT_DIR}/lib/system_setup.sh" \
        "${SCRIPT_DIR}/lib/linuxtoys.sh"; do
        if [[ -f "$lib_file" ]]; then
            # shellcheck source=/dev/null
            source "$lib_file"
        fi
    done
else
    USING_COMMON_LIB=false
    
    # Inline color definitions when library not available
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
fi

# Verify Bash version (requires 4.0+)
if declare -f check_bash_version >/dev/null 2>&1; then
	check_bash_version 4 0
else
	if ((BASH_VERSINFO[0] < 4)); then
		echo -e "${VERMELHO:-}❌ ERRO: Requer Bash 4.0 ou superior. Versão atual: ${BASH_VERSION}${NC:-}" >&2
		exit 1
	fi
fi

# Log directory and file
LOGFILE="${WELLARCH_LOG_FILE:-$HOME/.cache/wellarch/wellarch.log}"
mkdir -p "$(dirname "$LOGFILE")"

# Inline log_to_file if library not loaded
if [[ "$USING_COMMON_LIB" != true ]]; then
    log_to_file() {
        echo "$(date '+%Y-%m-%dT%H:%M:%S%z') $*" >> "$LOGFILE"
    }
fi

# Version (Semantic Versioning)
VERSION="${WELLARCH_VERSION:-15.1.0}"

# Configurações gerais
LOG_LEVEL="info"
LOG_LEVEL_NUM=2
DOWNLOAD_TIMEOUT="${DOWNLOAD_TIMEOUT:-300}"
DOWNLOAD_RETRIES="${DOWNLOAD_RETRIES:-3}"
DOWNLOAD_BACKOFF="${DOWNLOAD_BACKOFF:-3}"
NON_INTERACTIVE=false
SKIP_RESOLV_CONF=false
POST_CHECK=false

# Contadores de progresso
TOTAL_STEPS=15
CURRENT_STEP=0

# Função para mostrar progresso
show_progress() {
	local step_name="$1"
	CURRENT_STEP=$((CURRENT_STEP + 1))
	local bar_width=30
	local completed=$((CURRENT_STEP * bar_width / TOTAL_STEPS))
	local remaining=$((bar_width - completed))
	local bar=""
	local empty=""
	printf -v bar '%*s' "$completed" ''
	printf -v empty '%*s' "$remaining" ''
	bar=${bar// /#}
	empty=${empty// /-}
	printf "${ROXO}[%s%s]${NC} ${VERDE}%02d/%02d %s${NC}\n" \
		"$bar" "$empty" "$CURRENT_STEP" "$TOTAL_STEPS" "$step_name"
	log_to_file "[${CURRENT_STEP}/${TOTAL_STEPS}] ${step_name}"
}

# Logging helpers (inline definitions if library not loaded)
VERBOSE=false
if [[ "$USING_COMMON_LIB" != true ]]; then
    set_log_level() {
        case "${1,,}" in
            debug) LOG_LEVEL_NUM=3 ;;
            info) LOG_LEVEL_NUM=2 ;;
            warn|warning) LOG_LEVEL_NUM=1 ;;
            error) LOG_LEVEL_NUM=0 ;;
            *)
                echo -e "${VERMELHO}❌ LOG_LEVEL inválido: $1 (use debug|info|warn|error)${NC}"
                exit 1
                ;;
        esac
    }
    log_debug() { [[ "$VERBOSE" == true && "$LOG_LEVEL_NUM" -ge 3 ]] && echo -e "${AZUL}[DEBUG]${NC} $*"; }
    log_info() { [[ "$LOG_LEVEL_NUM" -ge 2 ]] && echo -e "${AZUL}$*${NC}"; }
    log_warn() { [[ "$LOG_LEVEL_NUM" -ge 1 ]] && echo -e "${AMARELO}$*${NC}"; }
    log_error() { [[ "$LOG_LEVEL_NUM" -ge 0 ]] && echo -e "${VERMELHO}$*${NC}"; }
fi

# ==============================================================================
# FUNÇÕES AUXILIARES (definidas apenas se `lib/common.sh` não estiver disponível)
# ==============================================================================
if [[ "$USING_COMMON_LIB" != true ]]; then
is_installed() {
	command -v "$1" &>/dev/null || return 1
}

is_pkg_installed() {
	pacman -Qi "$1" >/dev/null 2>&1
}

get_official_repo() {
	local pkg="$1"
	local repo
	for repo in core extra community multilib; do
		if pacman -Si "${repo}/$pkg" >/dev/null 2>&1; then
			echo "$repo"
			return 0
		fi
	done
	return 1
}

is_chaotic_pkg() {
	pacman -Si "chaotic-aur/$1" >/dev/null 2>&1
}

SKIPPED_STEPS=()

add_skipped_step() {
	local step="$1"
	SKIPPED_STEPS+=("$step")
}

backup_file() {
	local src="$1"
	local bak="$2"
	if [[ -f "$src" && ! -f "$bak" ]]; then
		if [ "$EUID" -eq 0 ]; then
			try_cmd cp "$src" "$bak" || true
		else
			try_cmd sudo cp "$src" "$bak" || true
		fi
		# When lib/common.sh is absent, keep track locally
		BACKUP_FILES+=("$src|$bak")
	fi
}

restore_backups() {
	if [[ ${#BACKUP_FILES[@]} -eq 0 ]]; then
		return 0
	fi
	log_warn "Restaurando backups críticos..."
	local pair src bak
	for pair in "${BACKUP_FILES[@]}"; do
		src="${pair%%|*}"
		bak="${pair##*|}"
		if [[ -f "$bak" ]]; then
			if [ "$EUID" -eq 0 ]; then
				try_cmd cp "$bak" "$src" || true
			else
				try_cmd sudo cp "$bak" "$src" || true
			fi
		fi
	done
}
fi

install_pkg_preferred() {
	local display_name="$1"
	shift
	local candidates=("$@")
	local pkg
	local repo

	for pkg in "${candidates[@]}"; do
		if is_pkg_installed "$pkg"; then
			echo "✅ $display_name ($pkg) já está instalado. Pulando."
			return 0
		fi
	done

	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo -e "${AMARELO}(dry-run) instalaria $display_name${NC}"
		return 0
	fi

	for pkg in "${candidates[@]}"; do
		repo=$(get_official_repo "$pkg" || true)
		if [[ -n "$repo" ]]; then
			if sudo_run_retry "Instalação de $display_name" pacman -S --needed "${repo}/$pkg" --noconfirm; then
				echo -e "${VERDE}✅ $display_name instalado (${pkg})!${NC}"
				INSTALLED_PACKAGES+=("$display_name")
				return 0
			fi
		fi
	done

	for pkg in "${candidates[@]}"; do
		if is_chaotic_pkg "$pkg"; then
			if sudo_run_retry "Instalação de $display_name (Chaotic AUR)" pacman -S --needed "chaotic-aur/$pkg" --noconfirm; then
				echo -e "${VERDE}✅ $display_name instalado (${pkg}) via Chaotic AUR!${NC}"
				INSTALLED_PACKAGES+=("$display_name")
				return 0
			fi
		fi
	done

	if is_installed "$AUR_HELPER"; then
		for pkg in "${candidates[@]}"; do
			if $AUR_HELPER -S --needed "$pkg" --noconfirm; then
				echo -e "${VERDE}✅ $display_name instalado (${pkg}) via AUR!${NC}"
				INSTALLED_PACKAGES+=("$display_name")
				return 0
			fi
		done
	fi

	echo -e "${VERMELHO}❌ Falha ao instalar $display_name.${NC}"
	FAILED_ITEMS+=("$display_name")
	return 1
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
	restore_backups
	exit 1
}

# Cleanup/Trap
SUDO_KEEPALIVE_PID=""
cleanup() {
	# kill sudo keepalive if running
	if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
		kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
	fi
	# delegate temp dirs cleanup to shared library function if available
	if declare -f cleanup_temp_dirs >/dev/null 2>&1; then
		cleanup_temp_dirs
	else
		# fallback: try to remove TMP_DIRS if present
		if [[ ${#TMP_DIRS[@]:-0} -gt 0 ]]; then
			for d in "${TMP_DIRS[@]:-}"; do
				if [[ -n "$d" && "$d" = /* && -e "$d" ]]; then
					rm -rf -- "$d" || true
				fi
			done
		fi
	fi
	# restore backups if function available
	if declare -f restore_backups >/dev/null 2>&1; then
		restore_backups
	fi
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
try_cmd() {
	if [[ "${DRY_RUN:-false}" == true ]]; then
		log_to_file "(dry-run) $*"
		return 0
	fi
	log_to_file "CMD: $*"
	"$@" >>"$LOGFILE" 2>&1
}

run_with_retry() {
	local label="$1"
	shift
	local attempt=1
	local max="$DOWNLOAD_RETRIES"
	local backoff="$DOWNLOAD_BACKOFF"
	if [[ -z "$max" || "$max" -lt 1 ]]; then
		max=1
	fi
	while true; do
		if [[ "$DOWNLOAD_TIMEOUT" -gt 0 ]] && command -v timeout >/dev/null 2>&1; then
			if try_cmd timeout "${DOWNLOAD_TIMEOUT}" "$@"; then
				return 0
			fi
		else
			if try_cmd "$@"; then
				return 0
			fi
		fi
		if (( attempt >= max )); then
			return 1
		fi
		log_warn "Tentativa ${attempt}/${max} falhou. Aguardando ${backoff}s para nova tentativa..."
		sleep "$backoff"
		attempt=$((attempt + 1))
		backoff=$((backoff * 2))
	done
}

run_cmd() {
	if ! try_cmd "$@"; then
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

sudo_run_retry() {
	local label="$1"
	shift
	if [ "$EUID" -eq 0 ]; then
		run_with_retry "$label" "$@"
	else
		run_with_retry "$label" sudo "$@"
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
	available=$(df "$HOME" 2>/dev/null | tail -1 | awk '{print $4}') || available=0
	if [[ -z "$available" ]]; then
		available=0
	fi
	local required=$((3 * 1024 * 1024)) # 3GB em KB
	if [[ "$available" -lt "$required" ]]; then
		echo -e "${AMARELO}⚠️  AVISO: Apenas $(numfmt --to=iec-i --suffix=B $((available * 1024))) disponíveis.${NC}"
		echo -e "${AMARELO}Recomendado: 3GB ou mais para Flatpaks e outras aplicações.${NC}"
		if [[ "$ASSUME_YES" == true ]]; then
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

check_dependencies() {
	local required_cmds=(
		pacman
		sudo
		grep
		awk
		df
		ping
		numfmt
		tee
		mkdir
		rm
		cp
		sed
		mktemp
	)
	local missing=()
	local cmd
	for cmd in "${required_cmds[@]}"; do
		if ! is_installed "$cmd"; then
			missing+=("$cmd")
		fi
	done
	if [[ ${#missing[@]} -gt 0 ]]; then
		echo -e "${VERMELHO}❌ Dependências ausentes: ${missing[*]}.${NC}"
		echo -e "${VERMELHO}Instale os pacotes necessários antes de continuar.${NC}"
		exit 1
	fi
}

validate_environment() {
	# 1. Checagem de Root
	if [ "$EUID" -eq 0 ]; then
		echo -e "${VERMELHO}⚠️  Não rode como root. Use ./script.sh (o script pedirá a senha).${NC}"
		exit 1
	fi

	check_dependencies

	# Verifica se é Arch Linux
	if ! grep -qi "arch" /etc/os-release; then
		echo -e "${VERMELHO}⚠️ Este script foi feito para Arch Linux. Saindo.${NC}"
		exit 1
	fi

	if [[ "${DRY_RUN:-false}" == true ]]; then
		log_info "(dry-run) pulando validação de permissões sudo."
	else
		log_info "🔑 Validando permissões sudo..."
		if ! sudo -v; then
			parar_com_erro "Acesso sudo recusado. Você precisa de privilégios sudo."
		fi
	fi

	# Verifica conectividade
	echo "🌐 Verificando conectividade com internet..."
	check_internet

	# Verifica espaço em disco
	echo "💾 Verificando espaço em disco..."
	check_disk_space
}

prompt_choice() {
	local prompt="$1"
	local default="$2"
	local choice
	if [[ "$ASSUME_YES" == true ]]; then
		echo "$default"
	else
		read -r -p "$prompt [$default]: " choice
		echo "${choice:-$default}"
	fi
}

# Garante toolchain básica antes de compilar pacotes do AUR
ensure_base_devel() {
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo "(dry-run) verificaria dependências de compilação"
		return 0
	fi

	if ! pacman -Qg base-devel >/dev/null 2>&1; then
		echo "🔧 Instalando base-devel (dependências de compilação)..."
		sudo_run_retry "Instalação de base-devel" pacman -S --needed base-devel --noconfirm
		log_to_file "base-devel instalado"
	else
		log_to_file "base-devel já presente"
	fi
	if ! is_installed git; then
		sudo_run_retry "Instalação de git" pacman -S --needed git --noconfirm
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
SAFE_MODE=true
FORCE_RESOLV_LOCK=false
SKIP_UPDATE=false
SKIP_MIRRORS=false
SKIP_CHAOTIC=false
SKIP_FLATPAK=false
SKIP_PAMAC=false
SKIP_EXTRAS=false
SKIP_DNS=false
SKIP_LINUXTOYS=false
SKIP_CLEANUP=false
SKIP_GPU=false
RESTART_SYSTEM=false
SAVE_CONFIG=false
CONFIG_FILE=""

# Load config file if specified via environment
if [[ -n "${WELLARCH_CONFIG:-}" && -f "$WELLARCH_CONFIG" ]]; then
    # shellcheck source=/dev/null
    source "$WELLARCH_CONFIG"
fi

while [ $# -gt 0 ]; do
	case "${1-}" in
	--uninstall)
		# Run uninstall script if available
		if [[ -f "${SCRIPT_DIR}/wellarch-remove.sh" ]]; then
			exec bash "${SCRIPT_DIR}/wellarch-remove.sh"
		elif [[ -f "$HOME/.local/bin/wellarch-remove.sh" ]]; then
			exec bash "$HOME/.local/bin/wellarch-remove.sh"
		else
			echo -e "${VERMELHO}❌ Script de desinstalação não encontrado.${NC}"
			echo "Baixe de: https://github.com/well-santos/WELLARCH"
			exit 1
		fi
		;;
	--config)
		if [[ -z "${2-}" ]]; then
			echo -e "${VERMELHO}❌ --config requer um caminho para arquivo.${NC}"
			exit 1
		fi
		CONFIG_FILE="$2"
		if [[ -f "$CONFIG_FILE" ]]; then
			# shellcheck source=/dev/null
			source "$CONFIG_FILE"
			echo -e "${AZUL}📄 Configuração carregada de $CONFIG_FILE${NC}"
		else
			echo -e "${VERMELHO}❌ Arquivo de configuração não encontrado: $CONFIG_FILE${NC}"
			exit 1
		fi
		shift 2
		;;
	--save-config)
		SAVE_CONFIG=true
		shift
		;;
	--dry-run)
		DRY_RUN=true
		ASSUME_YES=true
		shift
		;;
	--yes | -y)
		ASSUME_YES=true
		shift
		;;
	--unsafe)
		SAFE_MODE=false
		shift
		;;
	--safe)
		SAFE_MODE=true
		shift
		;;
	--verbose)
		VERBOSE=true
		shift
		;;
	--log-level)
		if [[ -z "${2-}" ]]; then
			echo -e "${VERMELHO}❌ --log-level requer um valor (debug|info|warn|error).${NC}"
			exit 1
		fi
		LOG_LEVEL="$2"
		set_log_level "$LOG_LEVEL"
		shift 2
		;;
	--download-timeout)
		if [[ -z "${2-}" || ! "${2-}" =~ ^[0-9]+$ ]]; then
			echo -e "${VERMELHO}❌ --download-timeout requer um número (segundos).${NC}"
			exit 1
		fi
		DOWNLOAD_TIMEOUT="$2"
		shift 2
		;;
	--download-retries)
		if [[ -z "${2-}" || ! "${2-}" =~ ^[0-9]+$ ]]; then
			echo -e "${VERMELHO}❌ --download-retries requer um número.${NC}"
			exit 1
		fi
		DOWNLOAD_RETRIES="$2"
		shift 2
		;;
	--non-interactive)
		NON_INTERACTIVE=true
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
	--skip-resolv-conf)
		SKIP_RESOLV_CONF=true
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
	--skip-extras)
		SKIP_EXTRAS=true
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
	--skip-gpu)
		SKIP_GPU=true
		shift
		;;
	--post-check)
		POST_CHECK=true
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
  --log-level NIVEL      Define nível de log (debug|info|warn|error)
  --download-timeout SEG Timeout de downloads em segundos (0 desativa)
  --download-retries N   Número de tentativas para downloads
  --non-interactive      Evita prompts (use com --yes)
  --version              Exibe versão do script
  --yes, -y              Assume "sim" para todos os prompts
  --safe                 Ativa modo seguro (bloqueia ações destrutivas por padrão)
  --unsafe               Permite ações destrutivas; desativa modo seguro
  --force-resolv-lock    Trava /etc/resolv.conf com chattr +i
  --skip-resolv-conf     Não sobrescreve /etc/resolv.conf
  --post-check           Executa verificação pós-instalação
  --config ARQUIVO       Carrega configuração de arquivo
  --save-config          Salva configurações atuais para arquivo
  --uninstall            Executa script de desinstalação
  --help, -h             Exibe este menu de ajuda

${AMARELO}OPÇÕES DE SKIP (pular etapas):${NC}
  --skip-update          Pula atualização do sistema (pacman -Syu)
  --skip-mirrors         Pula otimização de mirrors (reflector)
  --skip-chaotic         Pula configuração do Chaotic AUR
  --skip-flatpak         Pula instalação de Flatpak e apps
  --skip-pamac           Pula instalação do Pamac
  --skip-extras          Pula apps e temas essenciais
  --skip-dns             Pula configuração de DNS
  --skip-linuxtoys       Pula instalação do LinuxToys
  --skip-cleanup         Pula limpeza do sistema

${AMARELO}EXEMPLOS:${NC}
  # Executar normalmente:
  $0

# Modo automático (seguro por padrão):
	$0 --yes

	# Permitir ações destrutivas explícitas:
	$0 --unsafe --yes

  # Usar arquivo de configuração:
  $0 --config ~/.config/wellarch/config

  # Pular DNS e Flatpak:
  $0 --skip-dns --skip-flatpak

  # Simular execução:
  $0 --dry-run --yes

${AMARELO}DESINSTALAÇÃO:${NC}
  $0 --uninstall
  # ou
  ./wellarch-remove.sh
EOF
		exit 0
		;;
	*) break ;;
	esac
done

set_log_level "$LOG_LEVEL"
if [[ "$NON_INTERACTIVE" == true && "$ASSUME_YES" != true ]]; then
	log_error "❌ --non-interactive requer --yes para evitar prompts."
	exit 1
fi

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
║                        para Arch Linux v15.1                              ║
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
echo -e "   6. Apps e Temas Essenciais"
echo -e "   7. LinuxToys"
echo -e "   8. Configuração de DNS"
echo -e "   9. Configuração do Shell"
echo -e "  10. Limpeza do Sistema"
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

# Menu para escolher AUR Helper
echo ""
echo -e "${AMARELO}1. Qual AUR Helper você deseja?${NC}"
aur_choice=$(menu_select "Selecione o AUR Helper" "Paru (padrão, mais rápido)" \
	"Paru (padrão, mais rápido)" \
	"Yay (alternativa)")
case "$aur_choice" in
*"Yay"*)
	AUR_HELPER="yay"
	echo -e "${VERDE}✓ Escolhido: Yay${NC}"
	;;
*)
	AUR_HELPER="paru"
	echo -e "${VERDE}✓ Escolhido: Paru${NC}"
	;;
esac

# Menu para escolher Pamac
echo ""
echo -e "${AMARELO}2. Qual versão do Pamac você deseja?${NC}"
pamac_choice=$(menu_select "Selecione a versão do Pamac" "Pamac-all (com GUI + Flatpak + AUR, padrão)" \
	"Pamac-all (com GUI + Flatpak + AUR, padrão)" \
	"Pamac-aur (apenas CLI + AUR)")
case "$pamac_choice" in
*"pamac-aur"*)
	PAMAC_PKG="pamac-aur"
	echo -e "${VERDE}✓ Escolhido: Pamac-aur${NC}"
	;;
*)
	PAMAC_PKG="pamac-all"
	echo -e "${VERDE}✓ Escolhido: Pamac-all${NC}"
	;;
esac

# Menu para escolher DNS
echo ""
echo -e "${AMARELO}3. Qual provedor de DNS você deseja?${NC}"
dns_choice=$(menu_select "Selecione o provedor de DNS" "Cloudflare (padrão, 1.1.1.1) - Privacidade" \
	"Cloudflare (padrão, 1.1.1.1) - Privacidade" \
	"Quad9 (9.9.9.9) - Segurança" \
	"Google (8.8.8.8) - Velocidade" \
	"AdGuard (94.140.14.14) - Bloqueia anúncios" \
	"Manter padrão do sistema (sem alterações)")
case "$dns_choice" in
*"Quad9"*)
	DNS_PROVIDER="quad9"
	DNS_SERVERS="9.9.9.9,149.112.112.112,2620:fe::fe,2620:fe::9"
	echo -e "${VERDE}✓ Escolhido: Quad9${NC}"
	;;
*"Google"*)
	DNS_PROVIDER="google"
	DNS_SERVERS="8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844"
	echo -e "${VERDE}✓ Escolhido: Google DNS${NC}"
	;;
*"AdGuard"*)
	DNS_PROVIDER="adguard"
	DNS_SERVERS="94.140.14.14,94.140.15.15,2a10:50c0::ad1:ff,2a10:50c0::ad2:ff"
	echo -e "${VERDE}✓ Escolhido: AdGuard DNS${NC}"
	;;
*"Manter"*)
	DNS_PROVIDER="none"
	DNS_SERVERS=""
	echo -e "${VERDE}✓ Escolhido: Manter padrão do sistema${NC}"
	;;
*)
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
	"com.github.vesktop.Vesktop:Vesktop"
	"com.github.wwmm.easyeffects:Easy Effects"
	"io.github.flattool.Ignition:Ignition"
	"com.brave.Browser:Brave Browser"
	"io.github.Foldex.AdwSteamGtk:AdwSteamGtk"
	"com.mattjakeman.ExtensionManager:GNOME Extension Manager"
)

# Extrai apenas os nomes para apresentar no menu
APPS_NAMES=()
APPS_IDS=()
for app_info in "${AVAILABLE_APPS[@]}"; do
	app_id="${app_info%%:*}"
	app_name="${app_info##*:}"
	APPS_IDS+=("$app_id")
	APPS_NAMES+=("$app_name")
done

# Seleciona múltiplos apps
selected_names=$(menu_multiselect "Escolha os Flatpaks (Espaço para selecionar, Enter para confirmar)" "${APPS_NAMES[@]}")

SELECTED_APPS=()
if [ -n "$selected_names" ]; then
	# Mapeia nomes selecionados de volta para IDs
	for selected_name in $selected_names; do
		for i in "${!APPS_NAMES[@]}"; do
			if [[ "${APPS_NAMES[$i]}" == "$selected_name" ]]; then
				SELECTED_APPS+=("${APPS_IDS[$i]}")
				break
			fi
		done
	done
fi

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
	final_confirm=$(confirm "Confirmar e iniciar instalação?")
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

# Detecta GPU/CPU e prepara recomendações específicas para Intel
GPU_VENDOR="unknown"
if declare -f detect_gpu >/dev/null 2>&1; then
	GPU_VENDOR=$(detect_gpu || true)
fi
echo -e "${AZUL}🔍 GPU detectada: ${VERDE}${GPU_VENDOR}${NC}"

# Função para instalar intel-ucode quando CPU for Intel (recomendada para notebooks Intel)
ensure_intel_microcode() {
	if declare -f is_intel_cpu >/dev/null 2>&1 && is_intel_cpu; then
		if ! is_pkg_installed intel-ucode >/dev/null 2>&1; then
			echo -e "${AMARELO}ℹ️ CPU Intel detectada. Recomendado instalar 'intel-ucode'.${NC}"
			if [[ "${ASSUME_YES}" == "true" || "${DRY_RUN}" == "true" ]]; then
				install_pkg_preferred "Intel microcode" intel-ucode || true
			else
				read -r -p "Instalar intel-ucode agora? (y/n): " ans_micro
				if [[ "${ans_micro}" =~ ^[yY]$ ]]; then
					install_pkg_preferred "Intel microcode" intel-ucode || true
				else
					echo "Pulando instalação de intel-ucode. Lembre-se de instalar manualmente se necessário."
				fi
			fi
		fi
	fi
}

validate_environment

# Toolchain para builds do AUR
ensure_base_devel

# Se aplicável, recomenda/instala intel-ucode em CPUs Intel
ensure_intel_microcode || true

# Mantém sudo vivo (background) e guarda PID para cleanup
if [[ "${DRY_RUN:-false}" != true ]]; then
	start_sudo_keepalive
fi

# ---------------------------------------------------------
# 1. ATUALIZAÇÃO DO SISTEMA (pacman -Syu)
# ---------------------------------------------------------
update_system() {
	show_progress "Atualização do Sistema"
	
	if [[ "$SKIP_UPDATE" == true ]]; then
		echo -e "${AMARELO}⏭️  Pulando atualização do sistema (--skip-update)${NC}"
		add_skipped_step "Atualização do Sistema"
		return 0
	fi
	
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo -e "${AMARELO}(dry-run) pulando pacman -Syu${NC}"
		return 0
	fi
	
	if ! allow_destructive_action "Atualização do Sistema"; then
		echo -e "${AMARELO}⏭️  Modo seguro ativo: atualização do sistema bloqueada.${NC}"
		add_skipped_step "Atualização do Sistema (modo seguro)"
		return 0
	fi
	
	echo "🔄 Atualizando sistema com pacman -Syu..."
	if sudo_run_retry "Atualização do Sistema (pacman -Syu)" pacman -Syu --noconfirm; then
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
wellarch_setup_reflector

# ---------------------------------------------------------
# 3. CHAOTIC AUR
# ---------------------------------------------------------
wellarch_setup_chaotic_aur

# ---------------------------------------------------------
# 4. AUR HELPER (PARU OU YAY)
# ---------------------------------------------------------
wellarch_install_aur_helper

# ---------------------------------------------------------
# 5. FLATPAK & FLATHUB
# ---------------------------------------------------------
wellarch_setup_flatpak

# ---------------------------------------------------------
# 6. APPS FLATPAK
# ---------------------------------------------------------
wellarch_install_flatpak_apps

# ---------------------------------------------------------
# 7. PAMAC (via AUR Helper)
# ---------------------------------------------------------
wellarch_install_pamac

# ---------------------------------------------------------
# 8. TEMAS, APLICATIVOS E FERRAMENTAS
# ---------------------------------------------------------
wellarch_install_extras

# ---------------------------------------------------------
# 9. LINUXTOYS
# ---------------------------------------------------------
wellarch_install_linuxtoys

# ---------------------------------------------------------
# 10. DNS (SOLUÇÃO DEFINITIVA NETWORK MANAGER)
# ---------------------------------------------------------
wellarch_setup_dns

# ---------------------------------------------------------
# 11. CONFIGURAÇÃO DO SHELL
# ---------------------------------------------------------
wellarch_configure_oh_my_zsh

# Restaurar IFS original
IFS="$ORIGINAL_IFS"

# ---------------------------------------------------------
# 12. LIMPEZA
# ---------------------------------------------------------
wellarch_cleanup_system

# ---------------------------------------------------------
# VERIFICAÇÃO PÓS-INSTALAÇÃO (OPCIONAL)
# ---------------------------------------------------------
post_install_check() {
	echo -e "${AZUL}🔎 Verificação pós-instalação...${NC}"
	local failed=()
	local cmd
	local base_checks=(pacman sudo)
	for cmd in "${base_checks[@]}"; do
		if ! is_installed "$cmd"; then
			failed+=("$cmd")
		fi
	done
	if [[ "$SKIP_FLATPAK" != true ]] && ! is_installed flatpak; then
		failed+=("Flatpak")
	fi
	if [[ "$SKIP_PAMAC" != true ]] && ! is_installed pamac; then
		failed+=("Pamac")
	fi
	if [[ "$SKIP_LINUXTOYS" != true && -n "${MARKER_FILE:-}" && ! -f "$MARKER_FILE" ]]; then
		failed+=("LinuxToys (marker)")
	fi
	if [[ ${#failed[@]} -gt 0 ]]; then
		echo -e "${AMARELO}⚠️  Pós-instalação: itens ausentes: ${failed[*]}${NC}"
		FAILED_ITEMS+=("Post-check: ${failed[*]}")
	else
		echo -e "${VERDE}✅ Pós-instalação OK${NC}"
	fi
}

if [[ "$POST_CHECK" == true ]]; then
	post_install_check
fi

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

if [[ ${#SKIPPED_STEPS[@]} -gt 0 ]]; then
	echo -e "${AMARELO}⏭️  ETAPAS PULADAS:${NC}"
	for step in "${SKIPPED_STEPS[@]}"; do
		echo -e "   ${AMARELO}•${NC} $step"
	done
	echo ""
fi

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

# Salvar configuração se solicitado
if [[ "$SAVE_CONFIG" == true ]]; then
	CONFIG_DIR="${HOME}/.config/wellarch"
	mkdir -p "$CONFIG_DIR"
	CONFIG_SAVE_FILE="${CONFIG_FILE:-${CONFIG_DIR}/config}"
	
	cat > "$CONFIG_SAVE_FILE" << CONFIGEOF
# WELLARCH Configuration File
# Generated on $(date '+%Y-%m-%d %H:%M:%S')
# Use with: ./wellarch.sh --config $CONFIG_SAVE_FILE

# AUR Helper: paru or yay
AUR_HELPER="${AUR_HELPER}"

# Pamac Package: pamac-all or pamac-aur
PAMAC_PKG="${PAMAC_PKG}"

# DNS Provider: cloudflare, quad9, google, adguard, or none
DNS_PROVIDER="${DNS_PROVIDER}"

# Skip flags (true/false)
SKIP_UPDATE="${SKIP_UPDATE}"
SKIP_MIRRORS="${SKIP_MIRRORS}"
SKIP_CHAOTIC="${SKIP_CHAOTIC}"
SKIP_FLATPAK="${SKIP_FLATPAK}"
SKIP_PAMAC="${SKIP_PAMAC}"
SKIP_EXTRAS="${SKIP_EXTRAS}"
SKIP_DNS="${SKIP_DNS}"
SKIP_LINUXTOYS="${SKIP_LINUXTOYS}"
SKIP_CLEANUP="${SKIP_CLEANUP}"

# Other options
FORCE_RESOLV_LOCK="${FORCE_RESOLV_LOCK}"
SKIP_RESOLV_CONF="${SKIP_RESOLV_CONF}"
RESTART_SYSTEM="${RESTART_SYSTEM}"
CONFIGEOF
	
	echo -e "${VERDE}✅ Configuração salva em: $CONFIG_SAVE_FILE${NC}"
	echo ""
fi

# Gravar fim no log
log_to_file "=== WELLARCH v${VERSION} finalizado em ${ELAPSED_MIN}m ${ELAPSED_SEC}s ==="
log_to_file "Pacotes instalados: ${#INSTALLED_PACKAGES[@]} | Flatpaks: ${#INSTALLED_FLATPAKS[@]} | Falhas: ${#FAILED_ITEMS[@]}"

# Notificação desktop (se disponível)
if is_installed notify-send; then
	notify-send -i dialog-information "WELLARCH v${VERSION}" "Setup completo em ${ELAPSED_MIN}m ${ELAPSED_SEC}s! ✨" 2>/dev/null || true
fi

# Perguntar somente ao final, depois de concluir e mostrar o relatório.
if [[ "$ASSUME_YES" != true ]]; then
	read -r -p "Deseja reiniciar o computador agora? (y/n): " restart_choice
	case "${restart_choice,,}" in
		y | yes) RESTART_SYSTEM=true ;;
		*) RESTART_SYSTEM=false ;;
	esac
else
	RESTART_SYSTEM=false
fi

if [[ "$RESTART_SYSTEM" == true ]]; then
	if [[ "${DRY_RUN:-false}" == true ]]; then
		echo -e "${AMARELO}(dry-run) reinício do sistema solicitado; pulando.${NC}"
	else
		if ! allow_destructive_action "Reinicialização do Sistema"; then
			echo -e "${AMARELO}⏭️  Modo seguro ativo: reinicialização bloqueada.${NC}"
		else
			echo -e "${AMARELO}🔁 Reiniciando o sistema...${NC}"
			sudo_run systemctl reboot
		fi
	fi
fi

# Exit code baseado em falhas
if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
	exit 1
fi

exit 0