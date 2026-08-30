#!/bin/bash

# Teste interativo do multiselect
source lib/menu.sh

echo "=== TESTE INTERATIVO DO MULTISELECT ==="
echo ""
echo "Use as setas ↑↓ para navegar"
echo "Pressione ESPAÇO para marcar/desmarcar"
echo "Pressione ENTER para confirmar"
echo ""

result=$(menu_multiselect "Selecione os apps Flatpak:" \
    "GIMP" \
    "Blender" \
    "VS Code" \
    "Firefox" \
    "Telegram" \
    "Discord")

echo ""
echo "=== RESULTADO ==="
if [[ -z "$result" ]]; then
    echo "Nenhum app selecionado"
else
    echo "Apps selecionados:"
    for app in $result; do
        echo "  ✓ $app"
    done
fi
