# Contribuindo para o HeroDev Container

Obrigado por considerar contribuir para o HeroDev Container! Este documento fornece diretrizes para contribuições.

## Como contribuir

### Reportando bugs

Se você encontrou um bug, por favor abra uma issue incluindo:

1. **Descrição clara** do problema
2. **Passos para reproduzir** o bug
3. **Comportamento esperado** vs comportamento atual
4. **Ambiente**:
   - Sistema operacional (Windows/macOS)
   - Versão do Podman
   - Versão do HeroDev Container
5. **Logs relevantes** (se aplicável)
6. **Screenshots** (se ajudar a explicar)

### Sugerindo melhorias

Sugestões de novas funcionalidades são bem-vindas! Por favor:

1. **Verifique** se já não existe uma issue similar
2. **Descreva** claramente a funcionalidade desejada
3. **Explique** o caso de uso e benefícios
4. **Considere** a compatibilidade Windows/macOS

### Pull Requests

#### Antes de criar um PR

1. **Fork** o repositório
2. **Crie um branch** para sua feature/bugfix: `git checkout -b feature/nome-da-feature`
3. **Teste** suas mudanças em Windows E macOS (se possível)
4. **Siga** as convenções de código existentes
5. **Adicione** comentários quando necessário

#### Diretrizes para PRs

- **Um PR por funcionalidade/bugfix**
- **Descreva** claramente o que o PR faz
- **Referencie** issues relacionadas (`Fixes #123`)
- **Inclua** testes quando aplicável
- **Atualize** a documentação se necessário
- **Mantenha** commits atômicos e com mensagens descritivas

#### Convenções de commit

```
tipo(escopo): descrição curta

Descrição mais detalhada (opcional)

Fixes #123
```

**Tipos:**
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Apenas documentação
- `style`: Formatação, ponto e vírgula, etc (sem mudança de código)
- `refactor`: Refatoração de código
- `perf`: Melhoria de performance
- `test`: Adição ou correção de testes
- `chore`: Tarefas de build, configuração, etc

**Exemplos:**
```
feat(scripts): adiciona suporte para PostgreSQL

Implementa instalação opcional do PostgreSQL durante o build
e adiciona scripts de gerenciamento.

Fixes #45
```

```
fix(backup): corrige erro ao criar pasta de destino

O script de backup falhava ao tentar criar pasta com espaços
no caminho. Adicionado tratamento de aspas.

Fixes #67
```

### Áreas que precisam de ajuda

- **Suporte Linux nativo** (sem Podman Machine)
- **Novos serviços opcionais** (PostgreSQL, Elasticsearch, etc.)
- **Melhorias na documentação**
- **Traduções** (inglês, espanhol)
- **Interface do VSDesktop**
- **Testes automatizados**
- **Melhorias de segurança**

### Estrutura do projeto

```
herodev-cont/
├── Containerfile              # Definição da imagem Docker
├── README.md                  # Documentação principal
├── SECURITY.md                # Política de segurança
├── CONTRIBUTING.md            # Este arquivo
│
├── scripts/                   # Scripts executados dentro do container
│   ├── init-mariadb.sh       # Inicialização do MariaDB
│   ├── backup-db.sh          # Backup do banco de dados
│   └── ...
│
├── win_*.bat                  # Scripts para Windows
├── mac_*.sh                   # Scripts para macOS
│
└── volumes/                   # Dados persistentes (não versionados)
```

### Testando localmente

#### Windows

```cmd
REM Build da imagem
win_create-herodev.bat

REM Iniciar container
win_start-herodev.bat

REM Parar container
win_stop-herodev.bat
```

#### macOS

```bash
# Build da imagem
./mac_create-herodev.sh

# Iniciar container
./mac_start-herodev.sh

# Parar container
./mac_stop-herodev.sh
```

### Documentação

Ao adicionar novas funcionalidades, atualize:

1. **README.md** - Documentação principal
2. **Comentários nos scripts** - Documente funções complexas
3. **SECURITY.md** - Se envolve segurança ou credenciais
4. **Issues/PRs** - Mantenha discussões documentadas

### Estilo de código

#### Shell scripts (.sh)

```bash
#!/bin/bash

# Comentário descritivo da função
function nome_funcao() {
    local var_local="valor"
    
    if [ -z "$var_local" ]; then
        echo "Mensagem de erro" >&2
        return 1
    fi
    
    echo "Sucesso"
    return 0
}
```

#### Batch scripts (.bat)

```batch
@echo off
setlocal

REM Comentário descritivo
set VAR=valor

if "%VAR%"=="" (
    echo Erro: Variavel vazia
    exit /b 1
)

echo Sucesso
exit /b 0
```

### Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto (verificar LICENSE).

### Código de conduta

- Seja respeitoso e profissional
- Aceite feedback construtivo
- Foque no que é melhor para a comunidade
- Mostre empatia com outros contribuidores

### Dúvidas?

Se tiver dúvidas sobre como contribuir:

1. Abra uma **issue** com a tag `question`
2. Participe das **discussions**

---

**Obrigado por contribuir!**
