#!/bin/bash
# ==============================================================================
# TESTE DE DIAGNÓSTICO - Captura de Espaço
# ==============================================================================

echo "Teste de entrada de teclado - Diagnóstico"
echo "==========================================="
echo ""
echo "Pressione ESPAÇO e depois Enter para ver qual caractere foi capturado:"
echo ""

# Teste 1: read -n1
echo "Teste 1: usando read -n1"
stty -echo -icanon time 0 2>/dev/null
read -n1 key
stty sane 2>/dev/null
if [[ "$key" == " " ]]; then
    echo "✓ Funcionou! Caractere detectado: ESPAÇO (código ASCII 32)"
else
    echo "✗ Não funcionou. Caractere recebido: '$key' (código: $(printf '%d' "'$key"))"
fi

echo ""
echo "Teste 2: usando dd"
echo "Pressione ESPAÇO e depois Enter:"
stty -echo -icanon time 0 2>/dev/null
key=$(dd bs=1 count=1 2>/dev/null)
stty sane 2>/dev/null
if [[ "$key" == " " ]]; then
    echo "✓ Funcionou! Caractere detectado: ESPAÇO"
else
    echo "✗ Não funcionou. Caractere recebido: '$key'"
fi

echo ""
echo "Teste 3: usando read -s"
echo "Pressione ESPAÇO e depois Enter:"
read -s -n1 key
if [[ "$key" == " " ]]; then
    echo "✓ Funcionou! Caractere detectado: ESPAÇO"
else
    echo "✗ Não funcionou. Caractere recebido: '$key'"
fi
