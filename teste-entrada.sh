#!/bin/bash
# ==============================================================================
# TESTE DE ENTRADA - Verificar se espaço e setas funcionam
# ==============================================================================

set -euo pipefail

# Cores
VERDE='\033[1;32m'
AMARELO='\033[1;33m'
AZUL='\033[1;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Carregar menu
source "$SCRIPT_DIR/lib/menu.sh"

echo -e "${AZUL}═══════════════════════════════════════════════════════${NC}"
echo -e "${AMARELO}🧪 TESTE DE ENTRADA DE TECLADO${NC}"
echo -e "${AZUL}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${VERDE}Este teste verifica se seu terminal captura corretamente:${NC}"
echo -e "  • Setas para cima ↑ e baixo ↓"
echo -e "  • Espaço para selecionar/desselecionar"
echo -e "  • Enter para confirmar"
echo ""
echo -e "${AMARELO}Instruções:${NC}"
echo -e "  1. Use as setas ↑↓ para navegar entre as opções"
echo -e "  2. Pressione ESPAÇO para marcar/desmarcar"
echo -e "  3. Pressione ENTER para confirmar"
echo ""
echo -e "${AZUL}═══════════════════════════════════════════════════════${NC}"
echo ""

# Teste de seleção múltipla
selected=$(menu_multiselect "Selecione pelo menos 2 opções:" \
	"Opção 1" \
	"Opção 2" \
	"Opção 3" \
	"Opção 4" \
	"Opção 5")

echo ""
echo -e "${VERDE}✓ Você selecionou:${NC}"
if [[ -z "$selected" ]]; then
	echo -e "  ${AMARELO}(Nenhuma opção selecionada)${NC}"
else
	for opt in $selected; do
		echo -e "  ${VERDE}•${NC} $opt"
	done
fi

echo ""
echo -e "${AZUL}═══════════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✅ Teste de entrada concluído!${NC}"
echo ""
echo -e "${AMARELO}Se teve problemas:${NC}"
echo -e "  • Espaço não marcava: terminal pode ter problema com raw mode"
echo -e "  • Setas não funcionavam: sequência de escape não reconhecida"
echo -e "  • Nada funcionou: tente outro terminal (GNOME Terminal, Konsole, etc)"
echo ""
