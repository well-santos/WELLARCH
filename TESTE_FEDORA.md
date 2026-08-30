# 🧪 Guia de Testes do WELLARCH no Fedora

## ⚠️ Importante

O WELLARCH foi desenvolvido para **Arch Linux**. No Fedora, você pode testar a **interface de menus**, mas a instalação real não funcionará (usa `pacman`, AUR, etc).

---

## 📋 Opção 1: Testar Apenas a Interface (RECOMENDADO ⭐)

Isto permite testar os menus e fluxo de interação sem risco!

### Pré-requisitos
```bash
# Fedora
sudo dnf install bash fzf

# Verificar versão do Bash (precisa 4.0+)
echo $BASH_VERSION
```

### Teste da Interface
```bash
cd /path/to/wellarch
source lib/menu.sh

# Testar menu de seleção única
menu_select "Escolha um AUR Helper" "Paru" "Paru" "Yay"

# Testar menu de seleção múltipla
menu_multiselect "Escolha Flatpaks" "ZapZap" "Telegram" "Vesktop" "Easy Effects"

# Testar confirmação
confirm "Deseja continuar?"
```

---

## 📋 Opção 2: Modo Dry-Run (Simula sem Instalar)

Execute o script em modo de simulação - mostra o que faria sem fazer nada real:

```bash
./wellarch.sh --dry-run
```

**O que acontece:**
- ✅ Todos os menus funcionam normalmente
- ✅ Interface interativa é testada
- ❌ Nenhum pacote é instalado
- ❌ Nenhuma configuração é modificada
- 📝 Log mostra o que seria feito

**Saída esperada:**
```
⚙️  CONFIGURAÇÕES PRÉ-INSTALAÇÃO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Qual AUR Helper você deseja?
   [Interface fzf ou ASCII aparece aqui]

4. Selecione os aplicativos Flatpak a instalar:
   [Menu interativo com checkboxes]

[Após confirmar:]
   (dry-run) pulando instalação de paru
   (dry-run) pulando instalação de pamac-all
   (dry-run) pulando configuração de DNS
   ...
```

### Executar
```bash
cd ~/Documentos/WELLARCH
./wellarch.sh --dry-run --yes  # Usa defaults
# ou
./wellarch.sh --dry-run         # Interface completa
```

---

## 📋 Opção 3: Teste Isolado da Interface (Avançado)

Crie um script teste que carrega apenas as funções de menu:

```bash
# Criar arquivo teste-menu.sh
cat > teste-menu.sh << 'EOF'
#!/bin/bash

# Carregar biblioteca de cores
source lib/common.sh 2>/dev/null || {
    VERDE='\033[1;32m'
    AMARELO='\033[1;33m'
    AZUL='\033[1;34m'
    NC='\033[0m'
}

# Carregar biblioteca de menus
source lib/menu.sh

echo -e "${AMARELO}🧪 TESTE DE INTERFACE DE MENUS${NC}"
echo "═════════════════════════════════════════════════"
echo ""

# Teste 1: Menu de seleção única
echo -e "${AMARELO}1. Testando menu de seleção única...${NC}"
aur=$(menu_select "AUR Helper" "Paru" "Paru" "Yay")
echo -e "${VERDE}✓ Você escolheu: $aur${NC}"
echo ""

# Teste 2: Menu DNS
echo -e "${AMARELO}2. Testando menu com 5 opções (DNS)...${NC}"
dns=$(menu_select "Provedor de DNS" \
    "Cloudflare (padrão)" \
    "Cloudflare (padrão)" \
    "Quad9 (segurança)" \
    "Google (velocidade)" \
    "AdGuard (bloqueia anúncios)" \
    "Manter padrão")
echo -e "${VERDE}✓ DNS escolhido: $dns${NC}"
echo ""

# Teste 3: Menu de seleção múltipla
echo -e "${AMARELO}3. Testando seleção múltipla (Flatpaks)...${NC}"
flatpaks=$(menu_multiselect "Escolha Flatpaks" \
    "ZapZap (WhatsApp)" \
    "Telegram" \
    "Vesktop (Discord)" \
    "Easy Effects" \
    "Brave Browser")
echo -e "${VERDE}✓ Apps escolhidos: $flatpaks${NC}"
echo ""

# Teste 4: Confirmação
echo -e "${AMARELO}4. Testando confirmação...${NC}"
resultado=$(confirm "Confirmar tudo?")
if [[ "$resultado" =~ ^[yY]$ ]]; then
    echo -e "${VERDE}✓ Confirmado!${NC}"
else
    echo -e "${VERDE}✓ Cancelado!${NC}"
fi

echo ""
echo -e "${AZUL}═════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✅ Teste de interface concluído!${NC}"
EOF

chmod +x teste-menu.sh
./teste-menu.sh
```

---

## 📋 Opção 4: Usar VM do Arch Linux (Mais Completo)

Se quiser testar tudo funcionar de verdade:

### Rápido com Virtualbox
```bash
# 1. Baixar ISO do Arch
# https://archlinux.org/download/

# 2. Criar VM no VirtualBox
# - 2GB RAM mínimo
# - 20GB disk
# - Network: Bridge ou NAT

# 3. Instalar Arch minimal (não precisa de GUI)

# 4. No terminal da VM
pacman -Sy git bash
git clone seu-repo
cd wellarch
./wellarch.sh --dry-run
```

---

## 📋 Opção 5: Docker/Podman (Containers)

Testar em um container Arch isolado (sem VM):

```bash
# Fedora já tem podman
podman run -it --rm archlinux:latest bash

# Dentro do container
pacman -Sy git bash fzf
git clone <seu-repo>
cd wellarch
./wellarch.sh --dry-run
```

---

## 🎯 Recomendação de Teste

### Para você agora (Fedora):
```bash
# 1. Instalar fzf
sudo dnf install fzf

# 2. Ir para o diretório
cd ~/Documentos/WELLARCH

# 3. Testar com dry-run
./wellarch.sh --dry-run

# 4. Ou testar só os menus
source lib/menu.sh
menu_select "Teste" "Opção 1" "Opção 1" "Opção 2" "Opção 3"
```

---

## ✅ Checklist de Teste

Ao testar, verifique:

- [ ] **Menus aparecem corretamente** (com fzf ou fallback)
- [ ] **Navegação com setas funciona** (↑↓)
- [ ] **Espaço marca/desmarca** (seleção múltipla)
- [ ] **Enter confirma seleção**
- [ ] **Cores estão visíveis** (verde, amarelo, azul)
- [ ] **Mensagens de status aparecem** (✓ ✅)
- [ ] **Resumo das configurações é exibido**
- [ ] **Confirmação final funciona**

---

## 🐛 Troubleshooting

### "command not found: menu_select"
```bash
# Certifique-se que lib/menu.sh foi sourced
source lib/menu.sh
```

### Cores não aparecem
```bash
# Forçar cores mesmo sem tty
export TERM=xterm-256color
./wellarch.sh
```

### Setas não funcionam
```bash
# Alguns terminais precisam de stty
stty raw -echo
./wellarch.sh
```

### fzf não encontrado
```bash
# Instale fzf ou use o fallback (funciona sem fzf!)
sudo dnf install fzf
# ou use sem fzf, o fallback ASCII funciona perfeitamente
```

---

## 📊 Comparação de Opções

| Opção | Tempo | Seguro | Testa Interface | Testa Instalação |
|-------|-------|--------|-----------------|------------------|
| 1. Interface Isolada | ⚡ 5 min | ✅ Sim | ✅ Sim | ❌ Não |
| 2. Dry-Run | ⏱️ 10 min | ✅ Sim | ✅ Sim | ✅ Sim (simulado) |
| 3. Script Teste | ⏱️ 5 min | ✅ Sim | ✅ Sim | ❌ Não |
| 4. VM Arch | 🕐 1-2h | ✅ Sim | ✅ Sim | ✅ Sim (real) |
| 5. Docker/Podman | ⏱️ 20 min | ✅ Sim | ✅ Sim | ✅ Sim (real) |

---

## 🚀 Próximos Passos

Após testar:
1. Documentar comportamento observado
2. Reportar bugs/problemas
3. Fazer commits das mudanças
4. Fazer push para o repositório

