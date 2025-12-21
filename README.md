# WELLARCH v13.1 🚀

**Automação, Pós-Instalação e Otimização para Arch Linux.**

O **WELLARCH** é um script shell robusto projetado para transformar uma instalação base do Arch Linux em um sistema pronto para uso diário, com foco em performance, privacidade (DNS) e facilidade de gerenciamento.

---

## ✨ Funcionalidades

* **📦 AUR Helper Moderno:** Instalação e configuração automática do **Paru** (substituindo o Yay) compilado diretamente da fonte.
* **🌀 Chaotic AUR:** Adiciona automaticamente o repositório Chaotic AUR para instalações mais rápidas de pacotes do AUR.
* **🛍️ Pamac-all:** Instala a loja gráfica (GUI) com suporte a Flatpak e AUR.
* **🛡️ DNS Blindado (IPv4 & IPv6):**
    * Configura DNS da Cloudflare (`1.1.1.1` e IPv6) **diretamente no NetworkManager** (imune a reinicializações).
    * Por padrão, **não trava** `/etc/resolv.conf` (veja `--force-resolv-lock` para ativar).
* **📱 Flatpak & Flathub:** Configuração completa do ambiente Flatpak e repositório Flathub.
* **🧸 LinuxToys:** Integração automática com o conjunto de ferramentas LinuxToys (com download seguro e confirmação).
* **🧹 Limpeza Profunda:**
    * Remove pacotes órfãos (com confirmação interativa).
    * Limpa cache do Pacman e Paru (mantendo 2 versões para rollback).
    * Remove runtimes Flatpak não utilizados.
    * Rotaciona logs do sistema (Journalctl).

---

## 🚀 Instalação Rápida

Abra o terminal e cole o comando abaixo (não execute como root):

```bash
git clone https://github.com/well-santos/WELLARCH.git && cd WELLARCH && chmod +x wellarch.sh && ./wellarch.sh
```

---

## 🛠️ Opções e Flags

O script agora suporta os seguintes argumentos para maior controle e segurança:

```bash
./wellarch.sh [--dry-run] [--yes] [--force-resolv-lock] [--help]
```

### Flags Disponíveis

| Flag | Descrição |
|------|-----------|
| `--dry-run` | Simula a execução sem fazer alterações destrutivas no sistema. Ideal para testes e validação. |
| `--yes`, `-y` | Assume "sim" automaticamente para todos os prompts interativos (sem perguntar). |
| `--force-resolv-lock` | **Ativa** o travamento de `/etc/resolv.conf` com `chattr +i`. ⚠️ Use com cuidado — pode dificultar alterações futuras. |
| `--help`, `-h` | Exibe a mensagem de ajuda e sai. |

### Exemplos de Uso

```bash
# Modo seguro: simula sem fazer mudanças
./wellarch.sh --dry-run

# Execução automática (sem prompts)
./wellarch.sh --yes

# Ativar travamento do resolv.conf
./wellarch.sh --force-resolv-lock

# Combinar flags
./wellarch.sh --dry-run --yes
```

---

## 📋 Melhorias e Segurança (v13.1+)

Este script foi refatorado com as seguintes melhorias:

- ✅ **Modo Seguro:** `set -euo pipefail` para falhar rapidamente em erros críticos.
- ✅ **Cleanup Automático:** `trap` para limpeza de diretórios temporários mesmo em caso de erro ou interrupção (Ctrl+C).
- ✅ **Logging Completo:** Todas as saídas são registradas em `~/.cache/wellarch/wellarch.log` via `tee`.
- ✅ **Download Seguro:** LinuxToys é baixado em diretório temporário (`mktemp`), não executado via pipe, e pede confirmação antes de rodar.
- ✅ **Instalação Segura do Paru:** Usa `mktemp` para clonar o repositório, remove automaticamente a pasta de compilação.
- ✅ **DNS Não Travado por Padrão:** `/etc/resolv.conf` é atualizado mas **não travado** com `chattr +i`. Use `--force-resolv-lock` para ativar (não recomendado).
- ✅ **Limpeza Conservadora:** `paccache -rk 2` (mantém 2 versões) ao invés de `pacman -Sc` destrutivo.
- ✅ **Confirmações Interativas:** Remoção de órfãos e instalação do LinuxToys pedem confirmação (pode ser pulada com `--yes`).
- ✅ **Tratamento de Erros Consistente:** Novos comandos críticos usam `run_cmd()` que falha com mensagem clara e limpa tudo automaticamente.
- ✅ **Verificação de Distro:** Valida que você está rodando no Arch Linux antes de prosseguir.

---

## ⚠️ Como Desfazer Alterações

### Desfazer Travamento do `/etc/resolv.conf`

Se você usou `--force-resolv-lock` e quer desfazer:

```bash
sudo chattr -i /etc/resolv.conf
```

Depois, o NetworkManager gerenciará o arquivo normalmente.

### Remover DNS Cloudflare

Para voltar ao DNS padrão do sistema:

```bash
sudo rm -f /etc/NetworkManager/conf.d/99-cloudflare-dns.conf
sudo systemctl restart NetworkManager
```

### Reverter Chaotic AUR

Para remover o repositório Chaotic AUR:

```bash
# Editar o arquivo
sudo nano /etc/pacman.conf

# Remover as linhas:
# [chaotic-aur]
# Include = /etc/pacman.d/chaotic-mirrorlist
```

Depois atualize:

```bash
sudo pacman -Sy
```

### Remover LinuxToys

Delete o marcador para poder reinstalar:

```bash
rm -f ~/.config/linuxtoys_installed.marker
```

---

## 🔍 Verificar Logs

Para acompanhar o que o script fez:

```bash
cat ~/.cache/wellarch/wellarch.log
```

---

## 📝 Notas Importantes

- **Não execute como root:** O script pede a senha do sudo conforme necessário.
- **Pode levar tempo:** Dependendo de sua conexão, instalar o Paru e Flatpaks pode levar vários minutos.
- **Ative DNS apenas se confiar na Cloudflare:** A configuração usa `1.1.1.1` e IPv6 da Cloudflare.
- **Backup antes de usar:** Recomendado fazer um snapshot/backup antes de rodar em um sistema importante.

---

## 🤝 Contribuições

Sugestões, bugs e pull requests são bem-vindos! Abra uma issue ou envie um PR.

---

**Desenvolvido para:** Wesley  
**Versão:** v13.1 (Refatorada com melhorias de segurança)
