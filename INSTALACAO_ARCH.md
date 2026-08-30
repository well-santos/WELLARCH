# 📦 Guia de Instalação do WELLARCH no Arch Linux

## ✅ Instalação Recomendada

### Opção 1: Instalação Local (Recomendado)

```bash
cd ~/Documentos/WELLARCH
./wellarch.sh --dry-run
```

**Pré-requisitos:**
- Script e pasta `lib/` no mesmo diretório
- Bash 4.0+

---

## 🔧 Instalação para Todo o Sistema

### Opção 2: Instalação em /usr/local

```bash
sudo mkdir -p /usr/local/lib/wellarch
sudo cp wellarch.sh /usr/local/bin/wellarch
sudo cp -r lib/* /usr/local/lib/wellarch/
sudo chmod +x /usr/local/bin/wellarch
```

**Use assim:**
```bash
wellarch --dry-run
```

---

### Opção 3: Instalação por Variável de Ambiente

```bash
export WELLARCH_LIB_DIR=/caminho/para/lib
./wellarch.sh --dry-run
```

**Exemplo:**
```bash
export WELLARCH_LIB_DIR=$HOME/Documentos/WELLARCH/lib
$HOME/Documentos/WELLARCH/wellarch.sh --dry-run
```

---

## ❌ Erros Comuns

### Erro: "menu_select: comando não encontrado"

**Causa:** Biblioteca `lib/menu.sh` não encontrada

**Solução:**
```bash
# 1. Execute do diretório correto
cd /caminho/para/wellarch
./wellarch.sh

# 2. Ou especifique o caminho das libs
WELLARCH_LIB_DIR=/caminho/para/wellarch/lib ./wellarch.sh

# 3. Ou instale em /usr/local (ver Opção 2 acima)
```

---

## 🚀 Locais de Instalação Suportados

O script procura automaticamente em:

1. `./lib/` (diretório do script)
2. `../lib/` (diretório pai)
3. `$HOME/.local/lib/wellarch/`
4. `/usr/local/lib/wellarch/`
5. `/usr/lib/wellarch/`
6. `$WELLARCH_LIB_DIR` (variável de ambiente)

---

## 📝 Estrutura de Arquivos

```
wellarch/
├── wellarch.sh           # Script principal
├── lib/
│   ├── common.sh        # Definições de cores
│   ├── menu.sh          # Funções de menu
│   ├── aur.sh           # Gerenciamento de AUR
│   ├── flatpak.sh       # Funções de Flatpak
│   ├── dns.sh           # Configuração de DNS
│   ├── system.sh        # Funções do sistema
│   └── ... (outras libs)
└── README.md
```

---

## 💡 Dicas

### Teste Rápido (sem fazer alterações)
```bash
./wellarch.sh --dry-run
```

### Com Confirmação Automática
```bash
./wellarch.sh --yes
```

### Com Ambos
```bash
./wellarch.sh --dry-run --yes
```

### Teste de Menu Interativo
```bash
./teste-multiselect-interativo.sh
```

---

## 🔍 Verificar Carregamento de Bibliotecas

```bash
WELLARCH_LIB_DIR=./lib bash -c 'source lib/menu.sh && declare -f menu_select > /dev/null && echo "✓ OK" || echo "✗ Erro"'
```

---

## 📋 Requisitos Mínimos

- **Bash:** 4.0+
- **Ferramentas:** sed, grep, awk, stty
- **Terminal:** Suporte a cores ANSI (recomendado)

Verifique:
```bash
bash --version
stty --version
```

---

## 🐛 Debug

Se encontrar problema, use:

```bash
WELLARCH_LIB_DIR=/caminho/para/lib bash -x ./wellarch.sh 2>&1 | head -100
```

Isso mostrará cada linha de execução, ajudando a identificar o erro.

---

## ✨ Suporte

Se o erro persistir:

1. Verifique que `lib/menu.sh` existe:
   ```bash
   ls -la lib/menu.sh
   ```

2. Verifique permissões:
   ```bash
   chmod +x wellarch.sh
   chmod +x lib/*.sh
   ```

3. Teste a função diretamente:
   ```bash
   source lib/menu.sh
   menu_select "Test" "Option 1" "Option 2"
   ```

---

**Última atualização:** 2026-08-30  
**Versão:** WELLARCH v15.1.0
