#!/bin/bash

# ==============================================================================
# BIBLIOTECA DE MENUS INTERATIVOS - WELLARCH
# ==============================================================================
# Fornece funções para criar menus interativos com fzf ou fallback ASCII

# Cores devem ser importadas do common.sh ou definidas globalmente
# Não redefinir aqui para evitar conflitos com readonly

# ==============================================================================
# Menu de seleção única - versão simples e estável
# ==============================================================================
# Uso: menu_select "prompt" "opção_padrão" "opção1" "opção2" ...
menu_select() {
	local prompt="$1"
	shift
	local default_option="$1"
	shift
	local options=("$@")
	local cleaned=()
	local seen_default=0
	local item

	for item in "${options[@]}"; do
		if [[ "$item" == "$default_option" && "$seen_default" -eq 1 ]]; then
			continue
		fi
		if [[ "$item" == "$default_option" ]]; then
			seen_default=1
		fi
		cleaned+=("$item")
	done
	options=("${cleaned[@]}")

	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "$default_option"
		return 0
	fi

	if [[ ! -t 0 && ! -e /dev/tty ]]; then
		echo "$default_option"
		return 0
	fi

	local choice
	local input_source=""
	if [[ ! -t 0 && -e /dev/tty ]]; then
		input_source="</dev/tty"
	fi
	while true; do
		echo -e "${AMARELO}${prompt}${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo ""
		for i in "${!options[@]}"; do
			local num=$((i + 1))
			if [[ "${options[$i]}" == "$default_option" ]]; then
				echo -e "  ${VERDE}[${num}]${NC} ${options[$i]} ${AMARELO}(padrão)${NC}"
			else
				echo -e "  ${VERDE}[${num}]${NC} ${options[$i]}"
			fi
		done
		echo ""
		if [[ -n "$input_source" ]]; then
			read -r -p "Escolha uma opção [1-${#options[@]}] (Enter = padrão): " choice $input_source
		else
			read -r -p "Escolha uma opção [1-${#options[@]}] (Enter = padrão): " choice
		fi
		if [[ -z "$choice" ]]; then
			echo "$default_option"
			return 0
		fi

		if [[ "$choice" =~ ^[0-9]+$ ]]; then
			if (( choice >= 1 && choice <= ${#options[@]} )); then
				echo "${options[$((choice - 1))]}"
				return 0
			fi
		fi

		for opt in "${options[@]}"; do
			if [[ "$choice" == "$opt" ]]; then
				echo "$opt"
				return 0
			fi
		done

		echo -e "${VERMELHO}Opção inválida. Tente novamente.${NC}"
		echo ""
	done
}

# ==============================================================================
# Menu de seleção múltipla - versão simples e estável
# ==============================================================================
# Uso: menu_multiselect "prompt" "opção1" "opção2" ...
# Retorna: opções selecionadas em uma linha separada por espaço
menu_multiselect() {
	local prompt="$1"
	shift
	local options=("$@")

	if [[ "${ASSUME_YES:-false}" == true ]]; then
		echo "${options[@]}"
		return 0
	fi

	if [[ ! -t 0 && ! -e /dev/tty ]]; then
		echo ""
		return 0
	fi

	local selected=()
	local input=""
	local choice
	local input_source=""
	if [[ ! -t 0 && -e /dev/tty ]]; then
		input_source="</dev/tty"
	fi
	while true; do
		echo -e "${AMARELO}${prompt}${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		echo ""
		for i in "${!options[@]}"; do
			local num=$((i + 1))
			local marked="[ ]"
			for sel in "${selected[@]}"; do
				if [[ "$sel" == "${options[$i]}" ]]; then
					marked="[✓]"
					break
				fi
			done
			echo -e "  ${VERDE}[${num}]${NC} ${marked} ${options[$i]}"
		done
		echo ""
		echo -e "${AZUL}Digite os números separados por espaço e pressione Enter.${NC}"
		echo -e "${AZUL}Exemplo: 1 3 5   ou   0 para confirmar sem seleção${NC}"
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
		if [[ -n "$input_source" ]]; then
			read -r -p "Seleção: " input $input_source
		else
			read -r -p "Seleção: " input
		fi

		if [[ -z "$input" ]]; then
			if [[ ${#selected[@]} -gt 0 ]]; then
				echo "${selected[@]}"
				return 0
			fi
			continue
		fi

		if [[ "$input" == "0" ]]; then
			echo ""
			return 0
		fi

		selected=()
		for choice in $input; do
			if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
				selected+=("${options[$((choice - 1))]}")
			fi
		done
	
		# Se pelo menos uma opção foi selecionada, confirma
		if [[ ${#selected[@]} -gt 0 ]]; then
			echo "${selected[@]}"
			return 0
		fi
	
echo -e "${VERMELHO}Nenhuma opção válida foi escolhida.${NC}"
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
