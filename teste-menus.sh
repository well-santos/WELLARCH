#!/bin/bash
# ==============================================================================
# TESTE RÁPIDO DE MENUS - WELLARCH
# Executável em qualquer Linux (Fedora, Ubuntu, etc)
# ==============================================================================

set -euo pipefail

# Detectar cores
if [[ -t 1 ]]; then
	VERDE='\033[1;32m'
	AMARELO='\033[1;33m'
	VERMELHO='\033[0;31m'
	AZUL='\033[1;34m'
	ROXO='\033[1;35m'
	NC='\033[0m'
else
	VERDE=''
	AMARELO=''
	VERMELHO=''
	AZUL=''
	ROXO=''
	NC=''
fi

# Diretório do script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Verificações prévias
echo -e "${AMARELO}🔍 Verificando requisitos...${NC}"
echo ""

# Verificar Bash
if [[ ! "${BASH_VERSION%%.*}" -ge 4 ]]; then
	echo -e "${VERMELHO}❌ Bash 4.0+ é necessário (você tem $BASH_VERSION)${NC}"
	exit 1
fi
echo -e "${VERDE}✓ Bash $BASH_VERSION${NC}"

# Verificar se menu.sh existe
if [[ ! -f "$SCRIPT_DIR/lib/menu.sh" ]]; then
	echo -e "${VERMELHO}❌ lib/menu.sh não encontrado em $SCRIPT_DIR${NC}"
	exit 1
fi
echo -e "${VERDE}✓ lib/menu.sh encontrado${NC}"

# Verificar fzf
if command -v fzf &>/dev/null; then
	echo -e "${VERDE}✓ fzf instalado$(fzf --version)${NC}"
	FZF_AVAILABLE=true
else
	echo -e "${AMARELO}⚠️  fzf não instalado (usará fallback ASCII)${NC}"
	FZF_AVAILABLE=false
fi

echo ""
echo -e "${AZUL}═════════════════════════════════════════════════════════${NC}"
echo -e "${ROXO}     🧪 TESTE DE INTERFACE DE MENUS - WELLARCH${NC}"
echo -e "${AZUL}═════════════════════════════════════════════════════════${NC}"
echo ""

# Carregar biblioteca de menus
# shellcheck source=lib/menu.sh
source "$SCRIPT_DIR/lib/menu.sh"

# Teste 1: Menu de seleção única
echo -e "${AMARELO}Teste 1: Seleção Única (AUR Helper)${NC}"
echo "─────────────────────────────────────────────────────────"
aur=$(menu_select "Qual AUR Helper você deseja?" "Paru (padrão)" \
	"Paru (padrão, mais rápido)" \
	"Yay (alternativa)")
echo -e "${VERDE}✓ Você escolheu: $aur${NC}"
echo ""

# Teste 2: Menu com mais opções
echo -e "${AMARELO}Teste 2: Seleção Única com 5 Opções (DNS)${NC}"
echo "─────────────────────────────────────────────────────────"
dns=$(menu_select "Qual provedor de DNS você deseja?" "Cloudflare" \
	"Cloudflare (1.1.1.1) - Privacidade" \
	"Quad9 (9.9.9.9) - Segurança" \
	"Google (8.8.8.8) - Velocidade" \
	"AdGuard (94.140.14.14) - Bloqueia anúncios" \
	"Manter padrão do sistema")
echo -e "${VERDE}✓ DNS escolhido: $dns${NC}"
echo ""

# Teste 3: Menu de seleção múltipla
echo -e "${AMARELO}Teste 3: Seleção Múltipla (Flatpaks)${NC}"
echo "─────────────────────────────────────────────────────────"
echo -e "${AZUL}Dica: Use Espaço para marcar/desmarcar, Enter para confirmar${NC}"
echo ""
flatpaks=$(menu_multiselect "Escolha quais Flatpaks instalar:" \
	"ZapZap (WhatsApp)" \
	"Telegram" \
	"Vesktop (Discord)" \
	"Easy Effects" \
	"Ignition" \
	"Brave Browser")

if [[ -n "$flatpaks" ]]; then
	echo -e "${VERDE}✓ Apps escolhidos:${NC}"
	for app in $flatpaks; do
		echo -e "  ${VERDE}•${NC} $app"
	done
else
	echo -e "${AMARELO}⚠️  Nenhum app selecionado${NC}"
fi
echo ""

# Teste 4: Confirmação
echo -e "${AMARELO}Teste 4: Confirmação (Sim/Não)${NC}"
echo "─────────────────────────────────────────────────────────"
resultado=$(confirm "Confirmar tudo e continuar?")
if [[ "$resultado" =~ ^[yY]$ ]]; then
	echo -e "${VERDE}✓ Você confirmou!${NC}"
else
	echo -e "${VERDE}✓ Você cancelou!${NC}"
fi

echo ""
echo -e "${AZUL}═════════════════════════════════════════════════════════${NC}"

# Resumo
echo ""
echo -e "${ROXO}📋 RESUMO DO TESTE${NC}"
echo "─────────────────────────────────────────────────────────"
echo -e "  ${VERDE}✓${NC} Menu de seleção única: FUNCIONANDO"
echo -e "  ${VERDE}✓${NC} Menu com múltiplas opções: FUNCIONANDO"
echo -e "  ${VERDE}✓${NC} Menu de seleção múltipla: FUNCIONANDO"
echo -e "  ${VERDE}✓${NC} Confirmação: FUNCIONANDO"

if [[ "$FZF_AVAILABLE" == true ]]; then
	echo ""
	echo -e "  ${VERDE}✓${NC} Interface: ${AMARELO}fzf (moderna)${NC}"
else
	echo ""
	echo -e "  ${VERDE}✓${NC} Interface: ${AMARELO}ASCII fallback (setas/checkboxes)${NC}"
fi

echo ""
echo -e "${VERDE}✅ TESTE CONCLUÍDO COM SUCESSO!${NC}"
echo ""
echo -e "${AZUL}═════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${AZUL}Próximos passos:${NC}"
echo -e "  1. Executar: ${AMARELO}./wellarch.sh --dry-run${NC}"
echo -e "  2. Testar fluxo completo com dry-run (sem instalar nada)"
echo -e "  3. Verificar logs em: ${AMARELO}/tmp/wellarch*.log${NC}"
echo ""

