# Changelog - WELLARCH

> Nota: changelog histórico da v14.0. A versão atual do WELLARCH é v15.0.0.

## 🚀 Novas Funcionalidades

### Instalação via Curl
- **novo**: Script `install.sh` para instalação via curl
- **novo**: Suporte para instalação one-liner: `curl -sSL ... | bash`
- **novo**: Download automático do script de desinstalação
- **novo**: Validação de internet e curl antes da execução

### Melhorias no README
- **atualizado**: Documentação com 3 opções de instalação
- **atualizado**: Exemplos de uso para curl com argumentos
- **atualizado**: Seção de pré-requisitos aprimorada
- **atualizado**: Guia de desinstalação com 2 métodos

## 📝 Alterações

### Arquivos Criados
- `install.sh` - Script instalador que baixa e executa WELLARCH via curl

### Arquivos Modificados
- `README.md` - Documentação completa atualizada (v13.1 → v14.0)

## ✅ Benefícios

1. **Instalação mais rápida**: Não precisa clonar o repositório completo
2. **Compatível com padrões**: Segue o padrão de instalação de scripts populares
3. **Seguro**: Valida internet e curl antes de baixar
4. **Flexível**: Suporta argumentos via curl com `bash -s --`
5. **Melhor UX**: Feedback visual durante o download e execução

## 🔗 Exemplos de Uso

```bash
# Instalação rápida (recomendado)
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash

# Automática (sem prompts)
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --yes

# Teste seguro
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --dry-run --yes

# Modo verbose
curl -sSL https://raw.githubusercontent.com/well-santos/WELLARCH/main/install.sh | bash -s -- --verbose
```

## 🔒 Segurança

- ✅ Valida existência de curl antes de usar
- ✅ Verifica conectividade com internet (8.8.8.8 + 1.1.1.1)
- ✅ Não executa como root
- ✅ Limpeza automática de diretórios temporários
- ✅ Tratamento de erros com `set -euo pipefail`

## 📦 Compatibilidade

- ✅ Arch Linux (validado)
- ✅ Bash 4.0+
- ✅ curl (obrigatório para instalação via curl)
- ✅ Git (opcional para instalação clássica)

## 🐛 Problemas Conhecidos

Nenhum reportado até o momento.

---

**Data**: 11 de janeiro de 2026
**Versão**: 14.0
**Status**: Estável
