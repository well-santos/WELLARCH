# 📖 Como Usar WELLARCH v15.1.0

## ✅ Status: Versão Estável e Funcional

O WELLARCH v15.1.0 foi **restaurado e validado** como completamente funcional.

### Testes Realizados
- ✅ Validação de sintaxe bash: **PASSOU**
- ✅ Todos os scripts lib/: **PASSARAM**
- ✅ Execução com --dry-run: **PASSOU**
- ✅ Configurações interativas: **FUNCIONANDO**

---

## 🚀 Execução Rápida

### Modo Seco (Recomendado Primeiro)
```bash
cd /home/wesleysantos/Documentos/WELLARCH
./wellarch.sh --dry-run
```
Isso mostra **exatamente** o que seria feito, sem fazer mudanças no sistema.

### Modo Automático (Sem Perguntas)
```bash
./wellarch.sh --yes
```
Responde automaticamente com as opções padrão:
- AUR Helper: **Paru**
- Pamac: **Pamac-all** (GUI + AUR + Flatpak)
- DNS: **Cloudflare** (1.1.1.1)
- Flatpaks: **8 apps** (Blender, Krita, Discord, etc)

### Modo Interativo (Pergunte Antes de Fazer)
```bash
./wellarch.sh
```
Mostra prompts para você confirmar/escolher cada opção antes de executar.

---

## 📋 Opções Completas

| Opção | Descrição |
|-------|-----------|
| `--dry-run` | Simula tudo sem fazer alterações |
| `--yes` ou `-y` | Responde "sim" a tudo automaticamente |
| `--verbose` | Mostra mensagens de debug |
| `--skip-dns` | Não alterar DNS |
| `--skip-flatpak` | Não instalar Flatpak |
| `--skip-pamac` | Não instalar Pamac |
| `--skip-gpu` | Não instalar drivers GPU |
| `--skip-cleanup` | Não limpar sistema |
| `--help` | Mostra menu completo de ajuda |

### Exemplo Combinado
```bash
./wellarch.sh --dry-run --yes --verbose
```

---

## 📦 O Que o Script Faz

1. **Validação** - Verifica se é Arch Linux
2. **AUR Helper** - Instala Paru ou Yay
3. **Chaotic AUR** - Repositório extra de pacotes
4. **Flatpak** - Gerenciador de aplicativos
5. **Pamac** - Gerenciador gráfico de pacotes
6. **Apps Essenciais** - Ferramentas, temas, etc
7. **LinuxToys** - Script de utilitários
8. **DNS** - Cloudflare, Quad9, Google, AdGuard
9. **Shell** - Configuração de terminal
10. **Limpeza** - Remove arquivos temporários

---

## 🧪 Teste Completo

Para validar que tudo funciona:

```bash
# 1. Ver exatamente o que será feito
./wellarch.sh --dry-run --yes

# 2. Se tudo looks good, rodar de verdade
./wellarch.sh --yes

# 3. Ou rodar modo interativo
./wellarch.sh
```

---

## ❓ Dúvidas Comuns

### P: Preciso estar em Arch Linux?
**R**: Sim, este script foi feito especificamente para Arch Linux.

### P: Preciso ser root?
**R**: Não. O script pede sudo quando necessário.

### P: Posso pular algumas etapas?
**R**: Sim! Use `--skip-*` para pular qualquer coisa. Ex: `--skip-dns --skip-gpu`

### P: E se der erro?
**R**: Os erros são salvos em `~/.cache/wellarch/wellarch.log`. Verifique lá.

### P: Posso restaurar as alterações?
**R**: Use `./wellarch.sh --uninstall` para desinstalar tudo.

---

## 📄 Versão Atual

- **Versão**: WELLARCH v15.1.0
- **Status**: ✅ ESTÁVEL
- **Última Atualização**: 2024
- **Commit**: d6b4a1e (feat: Refatoração modular do WELLARCH para v15.1.0)

---

**Desenvolvido para**: Wesley  
**Compatibilidade**: Arch Linux  
**Requisitos**: Bash 4.0+, sudo, pacman  
**Dependências Opcionais**: git, fzf, vim, etc (o script instala)

