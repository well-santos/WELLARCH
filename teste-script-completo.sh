#!/bin/bash

echo "=== TESTE COMPLETO DO WELLARCH COM NOVO MENU MULTISELECT ==="
echo ""
echo "Testando Flatpaks menu (que usa multiselect)..."
echo ""

# Simular entrada: espaço para selecionar alguns, enter para confirmar
(
  sleep 0.5  # Aguarda prompt aparecer
  echo " "   # Espaço para marcar primeira opção
  sleep 0.3
  echo " "   # Espaço para marcar segunda opção
  sleep 0.3
  echo " "   # Enter para confirmar
) | ASSUME_YES=false ./wellarch.sh --dry-run

