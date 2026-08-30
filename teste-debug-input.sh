#!/bin/bash

echo "=== TESTE DE CAPTURA DE INPUT ==="
echo "Pressione ESPAÇO e veja o código ASCII"
echo ""

old_stty=$(stty -g 2>/dev/null) || true
stty -echo -icanon time 0 2>/dev/null || true

key=$(dd bs=1 count=1 2>/dev/null) || key=""

stty "$old_stty" 2>/dev/null || true

echo "Caractere capturado: '$key'"
echo "Representação hexadecimal: $(printf '%x' "'$key" 2>/dev/null || echo 'erro')"
echo "Código ASCII: $(printf '%d' "'$key" 2>/dev/null || echo 'erro')"

if [[ "$key" == $' ' ]]; then
    echo "✓ ESPAÇO detectado via comparação literal"
else
    echo "✗ Comparação literal falhou"
fi

if [[ $(printf '%d' "'$key" 2>/dev/null) == 32 ]]; then
    echo "✓ ESPAÇO detectado via ASCII 32"
else
    echo "✗ Comparação ASCII falhou"
fi
