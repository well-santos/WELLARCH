# WELLARCH v13.1

Automação, pós-instalação e otimização para Arch Linux.

O **WELLARCH** é um script de shell robusto projetado para transformar uma instalação base do Arch Linux em um sistema pronto para uso em produção, com foco em performance, segurança e facilidade de gerenciamento.

---

## Funcionalidades

- **AUR Helper:** Instalação automática e configuração do Paru, compilado diretamente da fonte.
- **Chaotic AUR:** Integração automática do repositório Chaotic AUR para instalações mais rápidas.
- **Pamac:** Instalação da interface gráfica com suporte a Flatpak e AUR.
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

## Melhorias de Segurança

O script foi desenvolvido com as seguintes práticas:

- Modo seguro com `set -euo pipefail` para falhar rapidamente em erros críticos.
- Limpeza automática de diretórios temporários mesmo em caso de erro ou interrupção.
- Logging completo registrado em `~/.cache/wellarch/wellarch.log`.
- Download seguro de ferramentas em diretório temporário com confirmação antes de execução.
- Instalação segura do Paru com remoção automática de arquivos temporários.
- Configuração de DNS não travada por padrão em `/etc/resolv.conf`.
- Limpeza conservadora que mantém 2 versões anteriores para rollback.
- Confirmações interativas para operações destrutivas.
- Validação de distribuição antes de prosseguir.

---

## Desfazendo Alterações

Para remover o travamento do `/etc/resolv.conf` (caso tenha usado `--force-resolv-lock`):

```bash
sudo chattr -i /etc/resolv.conf
```

O NetworkManager gerenciará o arquivo normalmente após isso.

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
