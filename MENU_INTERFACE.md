# 🎯 Nova Interface de Menus Interativos - WELLARCH

## Visão Geral

A versão melhorada do WELLARCH agora oferece uma interface de menus interativa e amigável usando:
- **fzf** (se disponível) - interface moderna com navegação rápida
- **Fallback ASCII** - menu com setas e checkboxes para sistemas sem fzf

---

## 📋 Recursos

### 1. Menu de Seleção Única (AUR Helper, Pamac, DNS)

#### Com fzf instalado:
- Interface limpa e moderna
- Navegação com ↑↓ setas
- Enter para confirmar
- Suporte a busca rápida

#### Sem fzf (fallback):
```
╭─────────────────────────────╮
│ Selecione o AUR Helper      │
╰─────────────────────────────╯

▶ Paru (padrão, mais rápido)
  Yay (alternativa)

Use ↑↓ para navegar e Enter para confirmar
```

### 2. Menu de Seleção Múltipla (Flatpaks)

#### Com fzf:
- Navegação com ↑↓
- **Espaço** para selecionar/desselecionar
- Enter para confirmar
- Suporte a busca enquanto seleciona

#### Sem fzf (fallback):
```
╭─────────────────────────────────────────────────╮
│ Escolha os Flatpaks                             │
│ (Espaço para selecionar, Enter para confirmar)  │
╰─────────────────────────────────────────────────╯

▶ [✓] ZapZap (WhatsApp)
  [ ] Telegram
  [✓] Vesktop
  [ ] Easy Effects
  ...

Selecionado(s): 2 | Use ↑↓ para navegar, Espaço para marcar, Enter para confirmar
```

---

## 🎮 Como Usar

### Instalação de fzf (Recomendado)

Para aproveitar a melhor experiência, instale o fzf:

```bash
# Arch Linux
sudo pacman -S fzf

# Debian/Ubuntu
sudo apt install fzf

# Fedora
sudo dnf install fzf

# Homebrew (macOS/Linux)
brew install fzf
```

### Executar o WELLARCH

```bash
# Com seleção interativa
./wellarch.sh

# Modo não-interativo (usa defaults)
./wellarch.sh --yes

# Dry-run com interface
./wellarch.sh --dry-run
```

---

## 📝 Controles

| Ação | Teclado |
|------|---------|
| **Navegar para cima** | ↑ |
| **Navegar para baixo** | ↓ |
| **Selecionar/Desselecionar** (múltipla) | Espaço |
| **Confirmar** | Enter |
| **Buscar** (com fzf) | Comece a digitar |
| **Cancelar** | Ctrl+C |

---

## 🔧 Arquitetura

### Arquivo: `lib/menu.sh`

Fornece as seguintes funções:

```bash
# Seleção única
menu_select "prompt" "opção_padrão" "opção1" "opção2" ...

# Seleção múltipla  
menu_multiselect "prompt" "opção1" "opção2" ...

# Confirmação simples
confirm "Deseja continuar?"

# Compatibilidade
prompt_choice "Qual a escolha?" "padrão"
```

### Comportamento

1. **Se fzf está instalado**: Usa fzf para interface moderna
2. **Se fzf não está disponível**: Usa fallback ASCII com setas e checkboxes
3. **Se --yes é usado**: Retorna padrões automaticamente (sem prompts)

---

## 💡 Exemplos de Uso

### Executar com interface completa
```bash
./wellarch.sh
# Abre menus interativos para: AUR Helper, Pamac, DNS, Flatpaks
```

### Executar com defaults (automatizado)
```bash
./wellarch.sh --yes
# Paru, Pamac-all, Cloudflare DNS, Todos os Flatpaks
```

### Teste do menu
```bash
source lib/menu.sh
menu_select "Teste" "Opção 1" "Opção 1" "Opção 2" "Opção 3"
```

---

## 🎨 Personalização

Você pode customizar cores e comportamento editando:
- `lib/menu.sh` - Funções de menu
- `lib/common.sh` - Cores e constantes globais

### Cores disponíveis
```bash
${VERDE}    # Verde
${AMARELO}  # Amarelo  
${VERMELHO} # Vermelho
${AZUL}     # Azul
${ROXO}     # Roxo
${NC}       # Limpar formatação
```

---

## 📊 Compatibilidade

| Sistema | Status | Notas |
|---------|--------|-------|
| Linux (Bash 4.0+) | ✅ Completo | Com/sem fzf |
| macOS | ✅ Completo | Com/sem fzf |
| WSL | ✅ Completo | Com/sem fzf |
| Arch Linux | ✅ Otimizado | Alvo principal |

---

## 🚀 Melhorias Futuras

- [ ] Suporte a atalhos customizáveis
- [ ] Temas de cores personalizáveis
- [ ] Modo compacto para displays pequenos
- [ ] Busca avançada com filtros

---

## 📞 Suporte

Para reportar problemas com a interface:
1. Verifique se fzf está instalado: `which fzf`
2. Teste o fallback: remova/renomeie fzf
3. Verifique a versão do Bash: `echo $BASH_VERSION`
4. Reporte no repositório do WELLARCH

