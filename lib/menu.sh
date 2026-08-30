#!/bin/bash

# ==============================================================================
# BIBLIOTECA DE MENUS INTERATIVOS - WELLARCH
# ==============================================================================
# Fornece funções para criar menus interativos com fzf ou fallback ASCII

# Cores devem ser importadas do common.sh ou definidas globalmente
# Não redefinir aqui para evitar conflitos com readonly

# ==============================================================================
# Menu de seleção única com fzf ou fallback
# ==============================================================================
# Uso: menu_select "prompt" "opção1" "opção2" ... "opção_padrão"
menu_select() {
	local prompt="$1"
	shift
	local default_option="$1"
	shift
	local options=("$@")

	# Se ASSUME_YES está ativo, retorna padrão
	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "$default_option"
		return 0
	fi

	# Tenta usar fzf se disponível
	if command -v fzf &>/dev/null; then
		local result=$(printf '%s\n' "${options[@]}" | fzf --height 10 --border --preview-window=hidden --header "$prompt" --no-info)
		if [ -n "$result" ]; then
			echo "$result"
		else
			echo "$default_option"
		fi
	else
		# Fallback: menu com setas
		_menu_select_fallback "$prompt" "$default_option" "${options[@]}"
	fi
}

# ==============================================================================
# Menu de seleção múltipla com fzf ou fallback
# ==============================================================================
# Uso: menu_multiselect "prompt" "opção1" "opção2" ... 
# Retorna: espaço separado de opções selecionadas
menu_multiselect() {
	local prompt="$1"
	shift
	local options=("$@")

	# Se ASSUME_YES está ativo, retorna todas
	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "${options[@]}"
		return 0
	fi

	# Usa fallback com setas e checkboxes (sem fzf, sem whiptail)
	_menu_multiselect_fallback "$prompt" "${options[@]}"
}

# ==============================================================================
# FALLBACK: Menu de seleção única com setas
# ==============================================================================
_menu_select_fallback() {
	local prompt="$1"
	local default_option="$2"
	shift 2
	local options=("$@")
	local selected=0
	local i
	local old_stty

	# Encontra índice da opção padrão
	for i in "${!options[@]}"; do
		if [[ "${options[$i]}" == "$default_option" ]]; then
			selected=$i
			break
		fi
	done

	# Salva estado do terminal
	old_stty=$(stty -g 2>/dev/null) || true

	# Configura terminal para modo raw
	stty -echo -icanon time 0 2>/dev/null || true

	while true; do
		clear
		echo -e "${AMARELO}$prompt${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo ""

		for i in "${!options[@]}"; do
			if [[ $i -eq $selected ]]; then
				echo -e "${VERDE}▶ ${options[$i]}${NC}"
			else
				echo -e "  ${options[$i]}"
			fi
		done

		echo ""
		echo -e "${AZUL}Use ↑↓ para navegar e Enter para confirmar${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

		# Lê input com dd (mais confiável)
		local key
		key=$(dd bs=1 count=1 2>/dev/null) || key=""

		if [[ "$key" == $'\n' || "$key" == $'\r' ]]; then
			# Enter pressionado
			stty "$old_stty" 2>/dev/null || true
			echo "${options[$selected]}"
			return 0
		elif [[ "$key" == $'\x1b' ]]; then
			# Sequência de escape (setas)
			local seq
			seq=$(dd bs=1 count=2 2>/dev/null) || seq=""
			case "$seq" in
			"[A") # Seta para cima
				((selected--))
				[[ $selected -lt 0 ]] && selected=$((${#options[@]} - 1))
				;;
			"[B") # Seta para baixo
				((selected++))
				[[ $selected -ge ${#options[@]} ]] && selected=0
				;;
			esac
		fi
	done
	stty "$old_stty" 2>/dev/null || true
}

# ==============================================================================
# FALLBACK: Menu de seleção múltipla com checkboxes (Simples & Robusto)
# ==============================================================================
_menu_multiselect_fallback() {
	local prompt="$1"
	shift
	local options=("$@")
	local selected=()
	local current=0
	local i

	# Inicializa todos como deselecionados
	for i in "${!options[@]}"; do
		selected[$i]=0
	done

	while true; do
		clear
		echo -e "${AMARELO}$prompt${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo ""

		# Mostra opções com checkboxes
		for i in "${!options[@]}"; do
			if [[ $i -eq $current ]]; then
				if [[ ${selected[$i]} -eq 1 ]]; then
					echo -e "${VERDE}▶ [✓] ${options[$i]}${NC}"
				else
					echo -e "${VERDE}▶ [ ] ${options[$i]}${NC}"
				fi
			else
				if [[ ${selected[$i]} -eq 1 ]]; then
					echo -e "  ${VERDE}[✓]${NC} ${options[$i]}"
				else
					echo -e "  [ ] ${options[$i]}"
				fi
			fi
		done

		local count=0
		for s in "${selected[@]}"; do
			[[ $s -eq 1 ]] && ((count++))
		done

		echo ""
		echo -e "${AZUL}Selecionado(s): ${VERDE}$count${AZUL}${NC}"
		echo ""
		echo -e "${AMARELO}Controles:${NC}"
		echo -e "  ${VERDE}↑↓${NC}      = Navegar"
		echo -e "  ${VERDE}ESPAÇO${NC}   = Marcar/desmarcar"
		echo -e "  ${VERDE}ENTER${NC}    = Confirmar"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

		# Lê input com read (mais portável que dd)
		local key
		# Desabilita canonical mode e echo
		read -rsN1 key

		# Trata Enter
		if [[ -z "$key" ]]; then
			local result=""
			for i in "${!options[@]}"; do
				if [[ ${selected[$i]} -eq 1 ]]; then
					result+="${options[$i]} "
				fi
			done
			echo "${result% }"
			return 0

		# Trata Espaço (ASCII 32)
		elif [[ "$key" == $' ' ]]; then
			selected[$current]=$((1 - selected[$current]))

		# Trata setas (ESC)
		elif [[ "$key" == $'\x1b' ]]; then
			# Lê os próximos 2 caracteres da sequência de seta
			local seq=""
			read -rsN1 -t 0.1 seq || true
			read -rsN1 -t 0.1 seq2 || true
			seq="$seq$seq2"

			case "$seq" in
			"[A") # Seta para cima
				((current--))
				[[ $current -lt 0 ]] && current=$((${#options[@]} - 1))
				;;
			"[B") # Seta para baixo
				((current++))
				[[ $current -ge ${#options[@]} ]] && current=0
				;;
			esac
		fi
	done
}

# ==============================================================================
# Exibe um prompt simples com input direto
# ==============================================================================
prompt_choice() {
	local prompt="$1"
	local default="$2"
	local choice

	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "$default"
	else
		read -r -p "$prompt [$default]: " choice
		echo "${choice:-$default}"
	fi
}

# ==============================================================================
# Exibe confirmação simples (S/N)
# ==============================================================================
confirm() {
	local prompt="$1"
	local default="${2:-n}"

	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "y"
		return 0
	fi

	if command -v fzf &>/dev/null; then
		local result=$(echo -e "Sim\nNão" | fzf --height 5 --border --header "$prompt" --no-info)
		[[ "$result" == "Sim" ]] && echo "y" || echo "n"
	else
		read -r -p "$prompt (s/n) [$default]: " choice
		choice="${choice:-$default}"
		[[ "$choice" =~ ^[sS]$ ]] && echo "y" || echo "n"
	fi
}

export -f menu_select
export -f menu_multiselect
export -f prompt_choice
export -f confirm
export -f _menu_select_fallback
export -f _menu_multiselect_fallback
