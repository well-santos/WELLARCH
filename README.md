# WELLARCH v15.1.0

Automação, pós-instalação e otimização para Arch Linux.

O **WELLARCH** é um script de shell robusto projetado para transformar uma instalação base do Arch Linux em um sistema pronto para uso em produção, com foco em performance, segurança e facilidade de gerenciamento.

---

## ✨ Novidades da v15.1.0

- **Biblioteca Compartilhada:** Novo `lib/common.sh` com funções reutilizáveis e constantes
- **Arquivo de Configuração:** Suporte a arquivo de configuração (`--config` e `--save-config`)
- **Flag --uninstall:** Desinstalar diretamente via `./wellarch.sh --uninstall`
- **Verificação de Bash:** Valida versão mínima do Bash (4.0+)
- **Plymouth Implementado:** Instalação completa do Plymouth com configuração de boot
- **Exit Code Correto:** Retorna código 1 quando há falhas
- **Testes Automatizados:** Suite de testes em `tests/test_functions.sh`
- **Makefile Melhorado:** Novos targets: `test`, `help`, `dry-run`
- **CONTRIBUTING.md:** Guia completo para contribuidores
- **Validação de Entrada:** Menus com validação de opções

### Novidades da v15.0.0

- **Skip Flags:** 10 novas flags para pular etapas específicas (veja abaixo)
- **Indicadores de Progresso:** Exibe passo atual e total durante execução
- **Mais Opções de DNS:** Agora com suporte a Google (8.8.8.8) e AdGuard
- **Atualização do Sistema:** Nova etapa para atualizar pacotes antes de instalar
- **Resumo de Configuração:** Exibe um sumário das opções antes de executar
- **Novas Flags de Controle:** `--log-level`, `--download-timeout`, `--download-retries`, `--non-interactive`, `--post-check`
- **DNS Mais Seguro:** opção `--skip-resolv-conf` para evitar sobrescrever `/etc/resolv.conf` (útil com systemd-resolved)
- **Downloads Mais Resilientes:** tentativas e timeouts configuráveis para pacman/flatpak/curl
- **Resumo de Etapas Puladas:** relatório final mostra quais etapas foram ignoradas
- **Backups/Restore Automático:** backups críticos e restauração em caso de erro fatal
- **Plymouth + Boot Splash:** instalação do Plymouth, tema padrão e ajuste do systemd-boot para splash/quiet
- **Cronômetro:** Mostra tempo total de execução ao final
- **Notificação Desktop:** Alerta via notify-send quando a instalação termina
- **Versionamento Semântico:** Adotado formato MAJOR.MINOR.PATCH

---

## Funcionalidades

- **AUR Helper:** Escolha entre Paru ou Yay (Instalação via Chaotic-AUR ou fallback binário do AUR).
- **Chaotic AUR:** Integração automática do repositório Chaotic AUR para instalações mais rápidas e helpers pré-compilados (quando disponível, tem prioridade sobre AUR).
- **Pamac:** Escolha entre Pamac-all (GUI completa) ou Pamac-aur (CLI).
- **Configuração de DNS:** Escolha entre Cloudflare, Quad9, Google ou AdGuard via NetworkManager.
- **Flatpak & Flathub:** Configuração completa do ambiente Flatpak e repositório Flathub.
- **Apps e Temas Essenciais:** Instala cursor Fluent, Papirus, GDM Settings, GNOME Themes Extra e Visual Studio Code.
- **Configuração Visual e Shell:** Aplica Papirus Dark, ícones legados Adwaita Dark e configura Oh My Zsh (tema duellj).
- **Plymouth & Boot Splash:** Instala Plymouth, define tema e habilita animação de boot (systemd-boot com timeout 0 e opções quiet/splash).
- **LinuxToys:** Integração com ferramentas essenciais (download seguro com confirmação).
- **Atualização do Sistema:** Atualiza todos os pacotes com `pacman -Syu` antes de instalar novos.
- **Limpeza do Sistema:**
  - Remoção de pacotes órfãos com confirmação interativa.
  - Limpeza de cache do Pacman e Paru (mantendo 2 versões para rollback).
  - Remoção de runtimes Flatpak não utilizados.
  - Rotação de logs do sistema.

---

## Instalação

### Opção 1: Instalação Rápida (Recomendado)

Abra o terminal e execute:

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
```

Esta é a forma mais simples e segura. O script:
- Valida sua conexão com a internet
- Baixa a versão mais recente do GitHub
- Executa imediatamente sem necessidade de clonar o repositório
 
Observação de integridade: o instalador primeiro tenta verificar uma **assinatura GPG** (`wellarch.sh.sig`) situada ao lado do script. Se a assinatura GPG não estiver disponível, o instalador tentará validar um arquivo SHA256 (`wellarch.sh.sha256`). Caso nenhuma verificação esteja disponível, a execução continua, mas isso reduz a segurança.

Para ativar a verificação GPG automática, publique a chave pública ASCII-armored em um caminho raw do GitHub (ex.: `pubkey.asc`) e exporte a variável `GPG_PUBKEY_URL` antes de executar o instalador. Exemplo:

```bash
export GPG_PUBKEY_URL="https://raw.githubusercontent.com/well-santos/WELLARCH/main/pubkey.asc"
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash
```

Como criar e publicar a assinatura e a chave pública:

1. Gere uma chave GPG (se ainda não tiver):

```bash
gpg --full-generate-key
```

2. Crie uma assinatura destacada para `wellarch.sh`:

```bash
gpg --armor --output wellarch.sh.sig --detach-sig wellarch.sh
```

3. Exporte sua chave pública e adicione ao repositório (ex.: `pubkey.asc`):

```bash
gpg --armor --output pubkey.asc --export <KEY_ID>
```

4. Faça upload de `wellarch.sh.sig` e `pubkey.asc` para o repositório (branch `main`) para que o instalador possa acessá-los via `raw.githubusercontent.com`.

### Opção 2: Instalação via Git

Se preferir clonar o repositório:

```bash
git clone https://github.com/well-santos/WELLARCH.git && cd WELLARCH && chmod +x wellarch.sh && ./wellarch.sh
```

### Opção 3: Instalação com Argumentos (Curl)

Se desejar passar argumentos ao script:

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --yes --verbose
```

Ou para teste seguro:

```bash
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --dry-run --yes
```

---

## Uso

### Instalador Automático (install.sh)

O script `install.sh` é um wrapper que:
- ✅ Valida a disponibilidade do `curl`
- ✅ Verifica conectividade com a internet
- ✅ Baixa a versão mais recente do WELLARCH
- ✅ Baixa o script de desinstalação para `~/.local/bin/wellarch-remove.sh`
- ✅ Executa o script principal com todos os argumentos passados

**Uso direto:**
```bash
bash install.sh [OPÇÕES]
bash install.sh --yes
bash install.sh --dry-run --verbose
```

### Menu Interativo de Configuração

Antes da execução, o script apresenta um **menu interativo** com 5 perguntas:

**1. AUR Helper (Gerenciador de AUR):**
- **a) Paru** (padrão) - Mais rápido e moderno, recomendado
- **b) Yay** - Alternativa tradicional

**2. Gerenciador de Pacotes (Pamac):**
- **a) Pamac-all** (padrão) - Interface gráfica completa com suporte a Flatpak e AUR
- **b) Pamac-aur** - Interface de linha de comando apenas para AUR

**3. Provedor de DNS:**
- **a) Cloudflare** (padrão) - DNS 1.1.1.1, foco em privacidade
- **b) Quad9** - DNS 9.9.9.9, foco em segurança
- **c) Google** - DNS 8.8.8.8, alta disponibilidade
- **d) AdGuard** - DNS 94.140.14.14, bloqueio de anúncios
- **e) Manter padrão** - Não fazer alterações de DNS

**4. Aplicativos Flatpak:**
Escolha quais apps deseja instalar:
- ZapZap (WhatsApp)
- Telegram
- ProtonPlus
- Equibop
- Easy Effects
- Ignition
- Brave Browser
- AdwSteamGtk
- GNOME Extension Manager

**5. Reinício do Sistema:**
Escolha se o sistema deve reiniciar automaticamente após a execução.

Você pode aceitar os padrões pressionando Enter, ou escolher suas preferências.

### Verificação de Pré-Requisitos

Antes de iniciar, o script valida:
- ✅ Você está em um sistema Arch Linux
- ✅ Tem acesso a `sudo` (sem necessidade de ser root)
- ✅ Conectividade com a internet (tenta ping em 8.8.8.8 e 1.1.1.1)
- ✅ Espaço em disco disponível (avisa se menos de 3GB, permite continuar)
- ✅ Verifica dependências básicas (pacman, sudo, grep, awk, df, ping, numfmt, tee, etc.)
- ✅ Cria backup automático de arquivos críticos (ex.: `/etc/pacman.conf`, mirrorlist, `resolv.conf` quando aplicável)

**Requisitos de Sistema:**
- Arch Linux atualizado (com pacman funcional)
- Acesso sudo (sem senha)
- curl (para usar via instalador)
- ~3GB de espaço livre (para Flatpaks e compilações)

### Argumentos de Linha de Comando

O script também suporta argumentos para maior controle e segurança:

```bash
./wellarch.sh [--dry-run] [--yes] [--log-level] [--download-timeout] [--download-retries] [--non-interactive] [--post-check] [--force-resolv-lock] [--skip-resolv-conf] [--skip-*] [--help]
```

### Flags Disponíveis

| Flag | Descrição |
|------|-----------|
| `--dry-run` | Simula a execução sem fazer alterações destrutivas no sistema. Ideal para testes e validação. |
| `--yes`, `-y` | Assume "sim" automaticamente para todos os prompts interativos (sem perguntar). |
| `--config ARQUIVO` | Carrega configurações de um arquivo. Exemplo: `--config ~/.config/wellarch/config` |
| `--save-config` | Salva as configurações atuais para arquivo após execução. |
| `--uninstall` | Executa o script de desinstalação para remover alterações do WELLARCH. |
| `--force-resolv-lock` | **Ativa** o travamento de `/etc/resolv.conf` com `chattr +i`. ⚠️ Use com cuidado — pode dificultar alterações futuras. |
| `--skip-resolv-conf` | Não sobrescreve `/etc/resolv.conf` (recomendado quando `systemd-resolved` está ativo). |
| `--log-level` | Define nível de log: `debug`, `info`, `warn`, `error`. |
| `--download-timeout` | Timeout de downloads em segundos (0 desativa). |
| `--download-retries` | Número de tentativas para downloads. |
| `--non-interactive` | Evita prompts (use em conjunto com `--yes`). |
| `--post-check` | Executa verificação pós-instalação. |
| `--skip-update` | Pula a etapa de atualização do sistema (pacman -Syu). |
| `--skip-mirrors` | Pula a otimização de mirrors com reflector. |
| `--skip-chaotic` | Pula a instalação do repositório Chaotic AUR. |
| `--skip-flatpak` | Pula a instalação do Flatpak e aplicativos Flathub. |
| `--skip-pamac` | Pula a instalação do Pamac (gerenciador de pacotes gráfico). |
| `--skip-extras` | Pula a instalação de apps e temas essenciais. |
| `--skip-dns` | Pula a configuração de DNS. |
| `--skip-linuxtoys` | Pula a instalação do LinuxToys. |
| `--skip-cleanup` | Pula a limpeza final do sistema. |
| `--skip-plymouth` | Pula a instalação e configuração do Plymouth boot splash. |
| `--verbose` | Exibe saída detalhada durante a execução. |
| `--version` | Exibe a versão do script. |
| `--help`, `-h` | Exibe a mensagem de ajuda e sai. |

### Exemplos de Uso

#### Via Curl (Recomendado)

```bash
# Instalação rápida com valores padrão (interativo)
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash

# Instalação automática sem prompts
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --yes

# Teste seguro (simula sem fazer mudanças)
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --dry-run --yes

# Pular etapas específicas
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --skip-flatpak --skip-pamac

# Com modo verbose para debug
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --verbose
```

#### Via Arquivo Local

```bash
# Modo seguro: simula sem fazer mudanças
./wellarch.sh --dry-run

# Execução automática (sem prompts, aceita padrões)
./wellarch.sh --yes

# Ativar travamento do resolv.conf
./wellarch.sh --force-resolv-lock

# Pular várias etapas
./wellarch.sh --skip-update --skip-mirrors --skip-cleanup

# Combinar flags
./wellarch.sh --dry-run --yes --skip-flatpak
```

---

## Relatório de Instalação

Ao final da execução, o script mostra um **relatório detalhado** com:
- ⏱️ **Tempo total** de execução
- Configurações selecionadas (AUR Helper, Pamac, DNS)
- Etapas puladas (se houver)
- Lista de pacotes instalados
- Lista de aplicativos Flatpak instalados
- Itens que falharam (se houver)
- Localização do log completo
- 🔔 **Notificação desktop** via notify-send (se disponível)

---

## Melhorias de Segurança

O script foi desenvolvido com as seguintes práticas:

- **Modo seguro** com `set -euo pipefail` para falhar rapidamente em erros críticos
- **Limpeza automática** de diretórios temporários mesmo em caso de erro ou interrupção
- **Logging completo** registrado em `~/.cache/wellarch/wellarch.log`
- **Download seguro** de ferramentas em diretório temporário com confirmação antes de execução
- **Retries e timeouts** configuráveis para downloads críticos
- **Instalação segura** compilando diretamente da fonte para AUR helpers
- **Backup automático** de arquivos críticos e **restauração em erro fatal**
- **Validação de internet** antes de fazer downloads
- **Verificação de espaço em disco** antes de instalar pacotes pesados
- **Confirmações interativas** para operações destrutivas
- **Validação de distribuição** e permissões antes de prosseguir

---

## Desinstalação

### Opção 1: Script de Desinstalação (se instalado via curl)

Se o script de desinstalação foi baixado:

```bash
~/.local/bin/wellarch-remove.sh
```

### Opção 2: Desinstalação Manual

Ou clone o repositório e execute:

```bash
git clone https://github.com/well-santos/WELLARCH.git && cd WELLARCH
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
- **Use curl para facilidade:** `curl -sSL ... | bash` é o padrão da indústria.
- **Git também funciona:** Se preferir clonar, a instalação clássica continua disponível.
- **Pode levar tempo:** Dependendo de sua conexão, instalar o Paru e Flatpaks pode levar vários minutos.
- **DNS é opcional:** A configuração de DNS usa Cloudflare por padrão, mas pode ser pulada.
- **Backup antes de usar:** Recomendado fazer um snapshot/backup antes de rodar em um sistema importante.
- **Teste com --dry-run primeiro:** Use `--dry-run` para simular sem fazer mudanças.

---

## 🤝 Contribuições

Sugestões, bugs e pull requests são bem-vindos! Abra uma issue ou envie um PR.

---

**Desenvolvido para:** Wesley  
**Versão:** v15.0.0 (Skip flags, indicadores de progresso, mais opções DNS, cronômetro)
