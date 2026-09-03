# 🚀 TESTE RÁPIDO NO FEDORA - 5 MINUTOS

## 1️⃣ Instalar fzf (Recomendado)
```bash
sudo dnf install fzf
```

## 2️⃣ Ir para o diretório
```bash
cd ~/Documentos/WELLARCH
```

## 3️⃣ Executar o teste (escolha uma opção)

### Opção A: Teste da Interface (Recomendado ⭐)
```bash
bash tests/test_functions.sh
```
✅ Testa todos os 4 tipos de menu  
✅ Funciona com ou sem fzf  
✅ Seguro, sem instalar nada  

### Opção B: Teste Completo (Dry-Run)
```bash
./wellarch.sh --dry-run
```
✅ Simula o fluxo completo  
✅ Mostra o que faria  
✅ ❌ Nada é instalado/modificado  

### Opção C: Teste Silencioso (Defaults)
```bash
bash tests/test_functions.sh  # Executa a suíte automatizada
# ou com defaults automáticos
./wellarch.sh --dry-run --yes
```

---

## 📊 O que Esperar

### Com fzf (instalado):
```
🔍 Verificando requisitos...
✓ Bash 5.1.16(1)-release
✓ lib/menu.sh encontrado
✓ fzf instalado (0.38.0)

🧪 TESTE DE INTERFACE DE MENUS - WELLARCH

Teste 1: Seleção Única (AUR Helper)
─────────────────────────────────────────────────────────

[Interface modern fzf aparece aqui com ↑↓ navigation]

✓ Você escolheu: Paru (padrão, mais rápido)
```

### Sem fzf (fallback):
```
[Interface ASCII com setas aparece aqui]

▶ Paru (padrão, mais rápido)
  Yay (alternativa)

Use ↑↓ para navegar e Enter para confirmar
```

---

## ✅ Checklist de Teste

- [ ] Instalar fzf: `sudo dnf install fzf`
- [ ] Executar: `bash tests/test_functions.sh`
- [ ] Conferir as opções numeradas
- [ ] Selecionar digitando o número e pressionando Enter
- [ ] Ver resumo final com ✅
- [ ] Documentar qualquer problema

---

## 🐛 Problemas Comuns & Soluções

| Problema | Solução |
|----------|---------|
| `tests/test_functions.sh` não executa | Verifique se o Bash 4+ está instalado |
| Cores não aparecem | `export TERM=xterm-256color` |
| Setas não funcionam | Tente outro terminal (GNOME Terminal, Konsole, etc) |
| fzf não encontrado | Use fallback (funciona sem fzf!) ou instale: `sudo dnf install fzf` |

---

## 📞 Feedback Esperado

Após executar, compartilhe:
```
✓ Qual teste você executou
✓ Se fzf estava disponível
✓ Se as cores apareceram
✓ Se a navegação funcionou
✓ Qualquer erro ou comportamento estranho
```

---

## 🎯 Resultado Esperado

```
📋 RESUMO DO TESTE
─────────────────────────────────────────────────────────
  ✓ Menu de seleção única: FUNCIONANDO
  ✓ Menu com múltiplas opções: FUNCIONANDO
  ✓ Menu de seleção múltipla: FUNCIONANDO
  ✓ Confirmação: FUNCIONANDO

  ✓ Interface: fzf (moderna)

✅ TESTE CONCLUÍDO COM SUCESSO!
```

---

## 🚀 Próximo Passo

Se tudo funcionar, você pode:
1. Fazer commits: `git add . && git commit -m "Nova interface de menus"`
2. Push para o repositório
3. Testar em VM/Container do Arch para instalação real

---

## 💡 Dica Pro

Para testar a instalação completa no Arch, use Docker:
```bash
podman run -it --rm archlinux:latest bash
# Dentro do container
pacman -Sy git bash fzf
git clone <seu-repo>
cd wellarch
./wellarch.sh --dry-run
```

Simples, rápido e seguro! ✨
