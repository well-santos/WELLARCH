# ✅ VERSÃO ESTÁVEL - v15.1.0

**Status**: ✅ FUNCIONAL E TESTADO

## Mudanças Nesta Versão

Voltamos para a versão estável e comprovadamente funcional: **d6b4a1e**

- ✅ Script principal funciona localmente: `./wellarch.sh --dry-run`
- ✅ Menu interativo simples e robusto
- ✅ Sem problemas de library loading
- ✅ Compatível com Arch Linux
- ✅ Modo dry-run funciona perfeitamente

## Como Usar

### Execução Local
```bash
./wellarch.sh --dry-run         # Ver o que seria feito
./wellarch.sh --yes             # Executar automaticamente
./wellarch.sh                   # Modo interativo
```

### Opções Disponíveis
- `--dry-run` - Simula execução sem fazer alterações
- `--yes` ou `-y` - Responde "sim" a todos os prompts
- `--verbose` - Modo detalhado
- `--help` - Exibe menu de ajuda completo
- `--skip-*` - Pula etapas específicas (DNS, Flatpak, etc)

## Problemas Resolvidos

Este commit reverte a complexidade desnecessária:

❌ ~~fzf com suporte a multiselect~~
❌ ~~read -rsN1 com arrow keys~~
❌ ~~menu_select() com lógica complexa~~
❌ ~~install.sh com pipe complications~~

✅ Interface simples e robusta
✅ Compatível com qualquer terminal
✅ Sem dependências extras
✅ Funciona via curl | bash

## Validação

O script foi validado com:
```bash
bash -n wellarch.sh              # Validação de sintaxe ✓
./wellarch.sh --dry-run --yes   # Execução em modo seco ✓
```

---

**Versão**: WELLARCH v15.1.0 (estável)
**Data de Estabilização**: 2024
