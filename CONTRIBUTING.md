# Contributing to WELLARCH

Obrigado pelo interesse em contribuir com o WELLARCH! 🎉

## 📋 Índice

- [Código de Conduta](#código-de-conduta)
- [Como Contribuir](#como-contribuir)
- [Padrões de Código](#padrões-de-código)
- [Fluxo de Trabalho](#fluxo-de-trabalho)
- [Testes](#testes)
- [Documentação](#documentação)

## 📜 Código de Conduta

Este projeto segue um código de conduta respeitoso. Esperamos que todos os contribuidores:
- Sejam respeitosos e construtivos em suas interações
- Aceitem feedback de forma profissional
- Foquem no melhor para a comunidade

## 🚀 Como Contribuir

### Reportando Bugs

1. Verifique se o bug já não foi reportado nas [Issues](https://github.com/well-santos/WELLARCH/issues)
2. Crie uma issue com:
   - Descrição clara do problema
   - Passos para reproduzir
   - Comportamento esperado vs atual
   - Versão do WELLARCH (`./wellarch.sh --version`)
   - Informações do sistema (Arch Linux, versão do kernel)

### Sugerindo Melhorias

1. Abra uma issue com a tag `enhancement`
2. Descreva:
   - O problema que a melhoria resolve
   - Como você imagina a solução
   - Alternativas consideradas

### Pull Requests

1. Fork o repositório
2. Crie uma branch para sua feature: `git checkout -b feature/minha-feature`
3. Faça suas alterações seguindo os padrões de código
4. Execute os testes: `make check`
5. Commit com mensagens descritivas
6. Push para sua branch
7. Abra um Pull Request

## 📐 Padrões de Código

### Estilo Bash

- Use `#!/bin/bash` como shebang
- Ative modo seguro: `set -euo pipefail`
- Use `[[ ]]` para testes condicionais (não `[ ]`)
- Declare variáveis locais em funções com `local`
- Use aspas duplas em variáveis: `"$variavel"`
- Nomeie funções em snake_case: `minha_funcao()`
- Constantes em UPPER_CASE: `MINHA_CONSTANTE`

### Exemplo de Função

```bash
# Descrição breve da função
# Argumentos:
#   $1 - Descrição do primeiro argumento
# Retorna:
#   0 - Sucesso
#   1 - Erro
minha_funcao() {
    local arg1="$1"
    local resultado
    
    if [[ -z "$arg1" ]]; then
        log_error "Argumento obrigatório não fornecido"
        return 1
    fi
    
    # Lógica da função
    resultado="processado: $arg1"
    
    echo "$resultado"
    return 0
}
```

### Convenções de Commit

Use mensagens de commit claras e descritivas:

```
tipo: descrição curta

Descrição mais detalhada se necessário.
```

Tipos:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação (não afeta lógica)
- `refactor`: Refatoração de código
- `test`: Adição/modificação de testes
- `chore`: Tarefas de manutenção

### Linting

Antes de submeter, execute:

```bash
make check    # Verifica sintaxe e lint
make format   # Formata o código com shfmt
```

Ferramentas necessárias:
- `shellcheck` - Análise estática de scripts shell
- `shfmt` - Formatador de shell scripts

Instale com:
```bash
make install-tools
```

## 🔄 Fluxo de Trabalho

1. **Fork & Clone**
   ```bash
   git clone https://github.com/SEU_USUARIO/WELLARCH.git
   cd WELLARCH
   ```

2. **Crie uma Branch**
   ```bash
   git checkout -b feature/minha-feature
   ```

3. **Desenvolva**
   - Faça alterações incrementais
   - Teste localmente com `--dry-run`
   - Execute `make check` frequentemente

4. **Teste**
   ```bash
   make test
   ./wellarch.sh --dry-run --yes
   ```

5. **Commit & Push**
   ```bash
   git add .
   git commit -m "feat: adiciona funcionalidade X"
   git push origin feature/minha-feature
   ```

6. **Pull Request**
   - Descreva as mudanças
   - Referencie issues relacionadas
   - Aguarde review

## 🧪 Testes

### Executando Testes

```bash
make test
```

### Teste Manual

```bash
# Modo dry-run (simula sem fazer alterações)
./wellarch.sh --dry-run --yes

# Com verbose
./wellarch.sh --dry-run --yes --verbose

# Testando flags específicas
./wellarch.sh --dry-run --skip-flatpak --skip-pamac
```

### Escrevendo Testes

Testes estão em `tests/`. Ao adicionar funcionalidades:

1. Adicione testes para a nova função
2. Teste casos de sucesso e erro
3. Teste edge cases

## 📚 Documentação

### README.md

Ao adicionar funcionalidades:
- Atualize a seção de funcionalidades
- Documente novas flags
- Adicione exemplos de uso

### Comentários no Código

- Comente lógica complexa
- Documente funções públicas
- Use TODO para melhorias futuras

## 🏷️ Versionamento

Usamos [Semantic Versioning](https://semver.org/):

- **MAJOR**: Mudanças incompatíveis com versões anteriores
- **MINOR**: Novas funcionalidades retrocompatíveis
- **PATCH**: Correções de bugs retrocompatíveis

## 📞 Contato

- Issues: [GitHub Issues](https://github.com/well-santos/WELLARCH/issues)
- Discussões: [GitHub Discussions](https://github.com/well-santos/WELLARCH/discussions)

---

Obrigado por contribuir! 🙏
