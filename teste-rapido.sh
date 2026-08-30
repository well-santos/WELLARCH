#!/bin/bash
source lib/menu.sh

echo "Testando seleção múltipla SEM fzf (apenas fallback robusto)"
echo ""

selected=$(menu_multiselect "Escolha os apps:" \
    "App 1" \
    "App 2" \
    "App 3" \
    "App 4")

echo ""
echo "Selecionados: $selected"
