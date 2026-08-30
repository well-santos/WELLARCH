# 🚀 Executar WELLARCH no Arch Linux via Curl

## ⚡ Método Recomendado (Uma Linha)

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
```

**O que acontece:**
- ✅ Detecta execução via pipe
- ✅ Clona repositório inteiro com git
- ✅ Baixa todas as bibliotecas
- ✅ Valida estrutura
- ✅ Executa com modo `--dry-run` por padrão
- ✅ Salva em `$HOME/.local/wellarch`

---

## 🔧 Variações do Comando

### Com Confirmação Automática (sem parar para perguntar)
```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -- --yes
```

### Com Argumentos Customizados
```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -- --verbose --dry-run
```

### Especificar Diretório de Instalação
```bash
WELLARCH_INSTALL_DIR=$HOME/meu-wellarch \
  curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
```

---

## 📋 Pré-requisitos

| Ferramenta | Necessário? | Como instalar |
|-----------|-----------|-----------------|
| **bash** 4.0+ | ✅ Sim | Geralmente pré-instalado |
| **curl** | ✅ Sim | `sudo pacman -S curl` |
| **git** | ⚠️ Recomendado | `sudo pacman -S git` (mais rápido) |

### Verificar versões:
```bash
bash --version
curl --version
git --version
```

---

## ✅ Teste Rápido

Se quer testar sem fazer nada:

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
# Usa --dry-run por padrão (seguro!)
```

---

## ❌ Erros Comuns e Soluções

### Erro: "curl: command not found"
```bash
# Solução:
sudo pacman -S curl
```

### Erro: "Ambiente sem TTY"
**Causa:** Terminal não interativo

**Solução:**
```bash
# Abra um terminal interativo e tente novamente
# Ou use xterm:
xterm -e 'curl -sSL ... | bash'
```

### Erro: "menu_select: comando não encontrado"
**Causa:** Bibliotecas não foram baixadas

**Solução:**
```bash
# Certifique-se que tem git:
sudo pacman -S git

# Tente novamente:
curl -sSL ... | bash
```

---

## 📍 Onde é Instalado

Por padrão, WELLARCH é instalado em:
```
$HOME/.local/wellarch/
├── wellarch.sh
└── lib/
    ├── common.sh
    ├── menu.sh
    ├── aur.sh
    ├── flatpak.sh
    └── ... (outras libs)
```

### Para Executar Novamente
```bash
WELLARCH_LIB_DIR=$HOME/.local/wellarch/lib bash $HOME/.local/wellarch/wellarch.sh
```

### Ou adicione ao `.bashrc`:
```bash
echo 'alias wellarch="WELLARCH_LIB_DIR=\$HOME/.local/wellarch/lib bash \$HOME/.local/wellarch/wellarch.sh"' >> $HOME/.bashrc
source $HOME/.bashrc

# Agora pode usar:
wellarch --help
```

---

## 🔄 Atualizar WELLARCH

Se já tem instalado, o script irá oferecer para atualizar:

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
# Pergunta: "Atualizar? (s/n)"
```

Ou force atualização:
```bash
rm -rf $HOME/.local/wellarch
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
```

---

## 💾 Alternativa: Clonar Manualmente

Se preferir ter controle total:

```bash
# Clonar repositório
git clone https://github.com/well-santos/WELLARCH.git
cd WELLARCH

# Executar
./wellarch.sh --dry-run

# Ou com instalação em /usr/local:
sudo mkdir -p /usr/local/lib/wellarch
sudo cp wellarch.sh /usr/local/bin/
sudo cp -r lib/* /usr/local/lib/wellarch/
sudo chmod +x /usr/local/bin/wellarch.sh
```

---

## 🔐 Segurança

O script `install.sh`:
- ✅ Valida estrutura antes de executar
- ✅ Oferece modo `--dry-run` por padrão
- ✅ Não requer sudo para download/instalação
- ✅ Pede confirmação se já existe instalação

**Conteúdo verificado:**
- Script principal: `wellarch.sh`
- Todas as 12 bibliotecas: `lib/*.sh`

---

## 📞 Suporte

Se encontrar erros:

1. **Verifique conexão de internet:**
   ```bash
   ping 8.8.8.8
   ```

2. **Teste git:**
   ```bash
   git clone https://github.com/well-santos/WELLARCH.git /tmp/test-wellarch
   ```

3. **Execute com debug:**
   ```bash
   bash -x <(curl -sSL ...) 2>&1 | head -100
   ```

4. **Acesse o repositório:**
   https://github.com/well-santos/WELLARCH

---

**Versão:** WELLARCH v15.1.0  
**Última atualização:** 2026-08-30
