# WELLARCH v13.1

Automação, pós-instalação e otimização para Arch Linux.

O **WELLARCH** é um script de shell robusto projetado para transformar uma instalação base do Arch Linux em um sistema pronto para uso em produção, com foco em performance, segurança e facilidade de gerenciamento.

---

## Funcionalidades

- **AUR Helper:** Escolha entre Paru ou Yay (compilado diretamente da fonte).
- **Chaotic AUR:** Integração automática do repositório Chaotic AUR para instalações mais rápidas.
- **Pamac:** Escolha entre Pamac-all (GUI completa) ou Pamac-aur (CLI).
- **Configuração de DNS:** Configuração de DNS Cloudflare (IPv4 e IPv6) via NetworkManager, com proteção de privacidade.
- **Flatpak & Flathub:** Configuração completa do ambiente Flatpak e repositório Flathub.
- **LinuxToys:** Integração com ferramentas essenciais (download seguro com confirmação).
- **Limpeza do Sistema:**
  - Remoção de pacotes órfãos com confirmação interativa.
  - Limpeza de cache do Pacman e Paru (mantendo 2 versões para rollback).
  - Remoção de runtimes Flatpak não utilizados.
  - Rotação de logs do sistema.

---

## Instalação

Abra o terminal e execute:

```bash
git clone https://github.com/well-santos/WELLARCH.git && cd WELLARCH && chmod +x wellarch.sh && ./wellarch.sh
```

---

## Uso

### Menu Interativo de Configuração

Antes da execução, o script apresenta um **menu interativo** com 4 perguntas:

**1. AUR Helper (Gerenciador de AUR):**
- **a) Paru** (padrão) - Mais rápido e moderno, recomendado
- **b) Yay** - Alternativa tradicional

**2. Gerenciador de Pacotes (Pamac):**
- **a) Pamac-all** (padrão) - Interface gráfica completa com suporte a Flatpak e AUR
- **b) Pamac-aur** - Interface de linha de comando apenas para AUR

**3. Provedor de DNS:**
- **a) Cloudflare** (padrão) - DNS 1.1.1.1, foco em privacidade
- **b) Quad9** - DNS 9.9.9.9, foco em segurança
- **c) Manter padrão** - Não fazer alterações de DNS

**4. Aplicativos Flatpak:**
Escolha quais apps deseja instalar:
- ZapZap (WhatsApp)
- Telegram
- ProtonPlus
- Equibop
- Easy Effects
- Ignition
- Brave Browser
- GNOME Extension Manager

Você pode aceitar os padrões pressionando Enter, ou escolher suas preferências.

### Verificação de Pré-Requisitos

Antes de iniciar, o script:
- Valida que você está no Arch Linux
- Verifica conectividade com internet
- Verifica espaço em disco disponível (avisa se menos de 3GB)
- Cria backup automático de `/etc/pacman.conf`

### Argumentos de Linha de Comando

O script também suporta argumentos para maior controle e segurança:

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

# Execução automática (sem prompts, aceita padrões)
./wellarch.sh --yes

# Ativar travamento do resolv.conf
./wellarch.sh --force-resolv-lock

# Combinar flags
./wellarch.sh --dry-run --yes
```

---

## Relatório de Instalação

Ao final da execução, o script mostra um **relatório detalhado** com:
- Configurações selecionadas (AUR Helper, Pamac, DNS)
- Lista de pacotes instalados
- Lista de aplicativos Flatpak instalados
- Itens que falharam (se houver)
- Localização do log completo

---

## Melhorias de Segurança

O script foi desenvolvido com as seguintes práticas:

- **Modo seguro** com `set -euo pipefail` para falhar rapidamente em erros críticos
- **Limpeza automática** de diretórios temporários mesmo em caso de erro ou interrupção
- **Logging completo** registrado em `~/.cache/wellarch/wellarch.log`
- **Download seguro** de ferramentas em diretório temporário com confirmação antes de execução
- **Instalação segura** compilando diretamente da fonte para AUR helpers
- **Backup automático** de `/etc/pacman.conf` antes de modificações
- **Validação de internet** antes de fazer downloads
- **Verificação de espaço em disco** antes de instalar pacotes pesados
- **Confirmações interativas** para operações destrutivas
- **Validação de distribuição** e permissões antes de prosseguir

---

## Desinstalação

Para remover todas as alterações feitas pelo WELLARCH, execute:

```bash
chmod +x wellarch-remove.sh
./wellarch-remove.sh
```

Este script:
- Remove o AUR Helper instalado (Paru ou Yay)
- Remove o repositório Chaotic AUR
- Remove Pamac
- Remove Flatpak e todos os apps instalados
- Remove configurações de DNS
- Restaura `/etc/pacman.conf` do backup (se disponível)
- Limpa marcadores de instalação

### Desfazendo Manualmente

Para remover o travamento do `/etc/resolv.conf` (caso tenha usado `--force-resolv-lock`):

```bash
sudo chattr -i /etc/resolv.conf
```

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
