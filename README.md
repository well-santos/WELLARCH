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
    * Trava o `/etc/resolv.conf` para evitar alterações indesejadas.
* **📱 Flatpak & Flathub:** Configuração completa do ambiente Flatpak e repositório Flathub.
* **🧸 LinuxToys:** Integração automática com o conjunto de ferramentas LinuxToys.
* **🧹 Limpeza Profunda:**
    * Remove pacotes órfãos.
    * Limpa cache do Pacman e Paru.
    * Remove runtimes Flatpak não utilizados.
    * Rotaciona logs do sistema (Journalctl).

---

## 🚀 Instalação Rápida

Abra o terminal e cole o comando abaixo (não execute como root):

```bash
git clone [https://github.com/well-santos/WELLARCH](https://github.com/well-santos/WELLARCH.git) && cd wellarch && chmod +x wellarch.sh && ./wellarch.sh