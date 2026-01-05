# HeroDev >>local<< Container

> **EXCLUSIVAMENTE PARA DESENVOLVIMENTO LOCAL**  

> Este projeto foi criado para facilitar o desenvolvimento local em Windows/macOS sem precisar instalar serviços individualmente. **NÃO é adequado para produção** e usa credenciais padrão intencionalmente para ser "ready-to-go". Todas as senhas estão documentadas e são necessárias para o funcionamento das ferramentas incluídas.

> **Projeto em desenvolvimento** - Esta aplicação está em constante evolução e não é um produto final. Oferecida "como está", sem suporte oficial. Contribuições via pull request são bem-vindas!

Ambiente de desenvolvimento local completo e portável baseado em containers Linux, executável em **Windows** e **macOS** via Podman. Inclui Apache, PHP, MariaDB, Node.js, Python e VS Code web em um único container com systemd habilitado.

## Índice

- [Visão geral](#visão-geral)
- [Requisitos](#requisitos)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Instalação](#instalação)
  - [Windows](#instalação-windows)
  - [macOS](#instalação-macos)
- [Uso](#uso)
  - [Windows](#uso-windows)
  - [macOS](#uso-macos)
- [Backup e sincronização](#backup-e-sincronização)
- [Serviços](#serviços)
- [Scripts Windows](#scripts-windows)
- [Scripts macOS](#scripts-macos)
- [Scripts do container](#scripts-do-container)
- [Containerfile](#containerfile)
- [Volumes](#volumes)
- [Configuração](#configuração)
- [VSDesktop](#vsdesktop)
- [Comandos úteis](#comandos-úteis)
- [Segurança](#segurança)
- [Solução de problemas](#solução-de-problemas)
- [Contribuindo](#contribuindo)
- [Licença](#licença)

---

## Visão geral

O HeroDev Container é um ambiente de desenvolvimento all-in-one que pode ser executado de qualquer local, incluindo drives externos. Todos os dados (banco de dados, projetos, configurações) são persistidos em volumes locais, garantindo **portabilidade entre Windows e macOS**.

### Componentes base

| Componente | Versão |
|------------|--------|
| Ubuntu | 22.04 LTS |
| Apache | 2.4 |
| PHP | 8.1 |
| MariaDB | 10.6 |
| Node.js | 20.x LTS |
| Python | 3.10 |
| code-server | Latest |
| phpMyAdmin | Latest |

---

## Requisitos

### Windows
- Windows 10/11 com **WSL2 habilitado**
- Podman Desktop 4.0+ ou Podman CLI

### macOS
- macOS 10.15+ (Catalina ou superior)
- Podman Desktop 4.0+ ou Podman CLI

### Hardware (ambos sistemas)
- RAM: 4GB mínimo (8GB recomendado)
- Disco: 10GB espaço livre

### Instalação do Podman

1. Download em: https://podman.io/getting-started/installation
2. Executar instalador
3. Reiniciar o sistema

## Estrutura do projeto

```
herodev-cont/
├── Containerfile                 # Definição da imagem
├── start.sh                      # Script interno do container
│
├── # ===== SCRIPTS WINDOWS =====
├── win_create-herodev.bat        # Build da imagem (Windows)
├── win_start-herodev.bat         # Inicia container (Windows)
├── win_stop-herodev.bat          # Para container (Windows)
├── win_backup-herodev.bat        # Backup do ambiente (Windows)
├── win_limpar_vm.bat             # Remove Podman Machine (Windows)
│
├── # ===== SCRIPTS MACOS =====
├── mac_create-herodev.sh         # Build da imagem (macOS)
├── mac_start-herodev.sh          # Inicia container (macOS)
├── mac_stop-herodev.sh           # Para container (macOS)
├── mac_backup-herodev.sh         # Backup do ambiente (macOS)
├── mac_limpar_vm.sh              # Remove Podman Machine (macOS)
├── mac_setup-vsdesktop.sh        # Compila VSDesktop (macOS)
│
├── scripts/                      # Scripts auxiliares do container
│   ├── backup-db.sh
│   ├── check-updates.sh
│   ├── healthcheck.sh
│   ├── herodev-info.sh
│   ├── herodev-projects.sh
│   ├── herodev-status.sh
│   ├── init-mariadb.sh
│   ├── install-wordpress.sh
│   └── restore-db.sh
│
└── volumes/                      # Dados persistentes (portáveis)
    ├── workspace/
    │   └── www/                  # DocumentRoot do Apache
    ├── db/                       # Dados do MariaDB
    └── vscode/
        ├── config/               # Configurações do code-server
        └── data/                 # Dados e extensões
```

---

## Instalação

### Instalação Windows

1. Clone ou copie o repositório:
```cmd
git clone https://github.com/herodjou/herodev-container.git
cd herodev-cont
```

2. Execute o script de criação:
```cmd
win_create-herodev.bat
```

O script irá:
- Verificar pré-requisitos (WSL2, Podman)
- Solicitar quais serviços opcionais instalar
- Inicializar a Podman Machine (se necessário)
- Construir a imagem `herodev-all`
- Executar automaticamente o `win_start-herodev.bat`

### Instalação macOS

1. Clone ou copie o repositório:
```bash
git clone https://github.com/herodjou/herodev-container.git
cd herodev-cont
```

2. **IMPORTANTE**: Dê permissão de execução aos scripts:
```bash
chmod +x mac_*.sh
chmod +x scripts/*.sh
```

3. Execute o script de criação:
```bash
./mac_create-herodev.sh
```

### Serviços opcionais no Build

Durante a criação, serão oferecidas as seguintes opções:

| Serviço | Descrição |
|---------|-----------|
| File Browser | Gerenciador de arquivos web |
| Redis | Cache em memória e filas |
| MongoDB + Mongo Express | Banco NoSQL com interface web |
| Nginx | Servidor web alternativo |
| Prometheus + Grafana | Monitoramento e dashboards |

---

## Uso

### Uso Windows

**Iniciar o ambiente:**
```cmd
win_start-herodev.bat
```

**Parar o ambiente:**
```cmd
win_stop-herodev.bat
```

**Fazer backup:**
```cmd
win_backup-herodev.bat
```

**Limpar instalação:**
```cmd
win_limpar_vm.bat
```

### Uso macOS

**Iniciar o ambiente:**
```bash
./mac_start-herodev.sh
```

**Parar o ambiente:**
```bash
./mac_stop-herodev.sh
```

**Fazer backup:**
```bash
./mac_backup-herodev.sh
```

**Limpar instalação:**
```bash
./mac_limpar_vm.sh
```

### Ações executadas ao iniciar

1. Cria estrutura de pastas se necessário
2. Inicia Podman Machine
3. Inicia ou cria container herodev
4. Inicia serviços core (Apache, MariaDB, code-server)
5. Inicia serviços opcionais instalados
6. Oferece opção de executar GUI (VSDesktop)

---

## Backup e sincronização

O HeroDev inclui scripts de backup para facilitar a sincronização entre máquinas Windows e macOS (via OneDrive, Google Drive, Dropbox, etc).

### Tipos de backup

| Tipo | Descrição |
|------|-----------|
| **Completo** | Todo o projeto (scripts + volumes) |
| **Volumes** | Apenas a pasta `volumes/` (dados) |

### Como usar

**Windows:**
```cmd
win_backup-herodev.bat
```

**macOS:**
```bash
./mac_backup-herodev.sh
```

### Funcionalidades

- **Detecta container rodando**: Pergunta se quer parar antes do backup
- **Lembra último destino**: Usa arquivo `.backup-config` para lembrar onde salvou
- **Nome fixo**: Sempre gera `backup-herodev.zip` (sobrescreve anterior)
- **Exclui arquivos desnecessários**: `.git`, `coder-logs`

### Fluxo de sincronização entre máquinas

1. **Máquina origem**: Execute o backup e salve em pasta sincronizada (OneDrive, etc)
2. **Aguarde sincronização** na nuvem
3. **Máquina destino**: Extraia o zip na pasta do HeroDev
4. Execute `win_start-herodev.bat` ou `./mac_start-herodev.sh`

> **Dica**: O backup de "volumes" é suficiente se você já tem os scripts nas duas máquinas. Use backup "completo" para primeira instalação.

---

## Serviços

### Serviços Core (Sempre disponíveis)

| Serviço | URL | Porta | Credenciais |
|---------|-----|-------|-------------|
| Apache | http://localhost:8080 | 8080 | - |
| phpMyAdmin | http://localhost:8080/phpmyadmin | 8080 | root / root |
| VS Code Server | http://localhost:12777 | 12777 | Senha: (verificar em `vscode/config/config.yaml`) |
| MariaDB | http://localhost:3306 | 3306 | root / root |

### Serviços opcionais

| Serviço | URL | Porta | Credenciais |
|---------|-----|-------|-------------|
| File Browser | http://localhost:8081 | 8081 | admin / adminadmin123 |
| Redis | http://localhost:6379 | 6379 | - |
| MongoDB | http://localhost:27017 | 27017 | - |
| Mongo Express | http://localhost:8082 | 8082 | admin / admin |
| Nginx | http://localhost:8083 | 8083 | - |
| Prometheus | http://localhost:9090 | 9090 | - |
| Grafana | http://localhost:3000 | 3000 | admin / admin |

---

## Scripts Windows (.bat)

### win_create-herodev.bat

Responsável pelo build inicial da imagem.

**Funcionalidades:**
- Detecta instalação do Podman automaticamente
- Solicita seleção de serviços opcionais interativamente
- Inicializa Podman Machine se inexistente
- Executa `podman build` com argumentos selecionados
- Chama `win_start-herodev.bat` ao finalizar

**Build Arguments suportados:**
```
--build-arg INSTALL_FILEBROWSER=true
--build-arg INSTALL_REDIS=true
--build-arg INSTALL_MONGODB=true
--build-arg INSTALL_NGINX=true
--build-arg INSTALL_PROMETHEUS=true
--build-arg INSTALL_GRAFANA=true
```

### win_start-herodev.bat

Inicia o ambiente de desenvolvimento.

**Funcionalidades:**
- Cria estrutura de diretórios em `volumes/`
- Inicia Podman Machine
- Cria container se inexistente ou inicia existente
- Configura mapeamento de portas
- Monta volumes persistentes
- Inicia serviços via systemd
- Oferece opção de GUI (VSDesktop)

**Mapeamento de portas:**
```
8080:80      - Apache
3306:3306    - MariaDB
12777:12777  - code-server
8081:8081    - File Browser
6379:6379    - Redis
27017:27017  - MongoDB
8082:8082    - Mongo Express
8083:8083    - Nginx
9090:9090    - Prometheus
3000:3000    - Grafana
```

### win_stop-herodev.bat

Para o ambiente de forma segura.

**Funcionalidades:**
- Para serviços internos (Apache, MariaDB)
- Para o container
- Para a Podman Machine

### win_setup-vsdesktop.bat

Compila a aplicação VSDesktop.

**Funcionalidades:**
- Verifica se container está rodando
- Clona repositório se necessário
- Instala dependências npm
- Compila aplicação para Windows (x64)
- Oferece execução após build

### win_limpar_vm.bat

Remove completamente a instalação do Podman Machine.

**Comandos executados:**
```cmd
podman machine stop
podman machine rm -f
podman system connection rm podman-machine-default
podman system connection rm podman-machine-default-root
```

### win_backup-herodev.bat

Realiza backup do ambiente para sincronização via nuvem.

**Funcionalidades:**
- Detecta se container está rodando (recomenda parar antes)
- Lembra último destino usado (arquivo `.backup-config`)
- Dois modos de backup: Completo ou apenas Volumes
- Exclui automaticamente `.git`, `coder-logs`, `node_modules`
- Gera arquivo `backup-herodev.zip` (nome fixo para sync)

**Uso:**
```cmd
win_backup-herodev.bat
```

---

## Scripts macOS (.sh)

> **Importante**: No macOS, é necessário dar permissão de execução aos scripts antes do primeiro uso:
> ```bash
> chmod +x mac_*.sh
> ```

### mac_create-herodev.sh

Equivalente macOS do script de build.

**Uso:**
```bash
./mac_create-herodev.sh
# ou
bash mac_create-herodev.sh
```

**Funcionalidades:**
- Detecta instalação do Podman
- Seleção interativa de serviços opcionais
- Inicializa Podman Machine
- Executa build com argumentos selecionados

### mac_start-herodev.sh

Inicia o ambiente no macOS.

**Uso:**
```bash
./mac_start-herodev.sh
```

**Funcionalidades:**
- Cria estrutura de diretórios
- Inicia Podman Machine
- Gerencia container (cria ou inicia existente)
- Oferece opção de GUI (VSDesktop)

### mac_stop-herodev.sh

Para o ambiente de forma segura no macOS.

**Uso:**
```bash
./mac_stop-herodev.sh
```

### mac_setup-vsdesktop.sh

Compila a aplicação VSDesktop para macOS.

**Uso:**
```bash
./mac_setup-vsdesktop.sh
```

### mac_limpar_vm.sh

Remove completamente a instalação do Podman Machine no macOS.

**Uso:**
```bash
./mac_limpar_vm.sh
```

### mac_backup-herodev.sh

Realiza backup do ambiente no macOS.

**Funcionalidades:**
- Detecta se container está rodando
- Lembra último destino usado
- Dois modos: Completo ou apenas Volumes
- Exclui `.git`, `coder-logs`, `node_modules`
- Gera `backup-herodev.zip`

**Uso:**
```bash
./mac_backup-herodev.sh
```

---

## Scripts do container

Scripts auxiliares instalados dentro do container em `/usr/local/bin/`.

### herodev-status

Retorna status de um serviço em formato JSON.

**Uso:**
```bash
herodev-status <nome-serviço>
```

**Exemplo:**
```bash
herodev-status apache2
```

**Retorno:**
```json
{
  "service": "apache2",
  "status": "running",
  "pid": 1234,
  "uptime": "2024-01-01 10:00:00",
  "memory": 12345678
}
```

### herodev-info

Retorna informações do sistema em formato JSON.

**Uso:**
```bash
herodev-info
```

**Retorno:**
```json
{
  "hostname": "herodev",
  "os": "Ubuntu 22.04",
  "kernel": "5.15.0",
  "php_version": "8.1.0",
  "node_version": "v20.0.0",
  "npm_version": "10.0.0",
  "python_version": "3.10.0",
  "mysql_version": "10.6.0",
  "apache_version": "2.4.52",
  "uptime": "up 2 hours",
  "load_average": "0.50 0.30 0.20",
  "memory_total": "8192",
  "memory_used": "4096",
  "disk_total": "50G",
  "disk_used": "20G",
  "disk_percent": "40"
}
```

### herodev-projects

Scanner de projetos no workspace com detecção de framework.

**Uso:**
```bash
herodev-projects [caminho]
```

**Frameworks detectáveis:**
- PHP: Laravel, WordPress, Symfony
- Node.js: React, Next.js, Vue.js, Nuxt, Angular, Express, NestJS, Svelte, Gatsby
- Python: Django, Flask, FastAPI

**Retorno:**
```json
[
  {
    "name": "meu-projeto",
    "path": "/workspace/www/meu-projeto",
    "language": "php",
    "framework": "Laravel",
    "lastModified": 1704067200,
    "isGitRepo": "true",
    "gitRemote": "https://github.com/usuario/repo.git"
  }
]
```

### herodev-health

Verifica saúde de todos os serviços.

**Uso:**
```bash
herodev-health
```

**Retorno:**
```json
{
  "timestamp": "2024-01-01T10:00:00-03:00",
  "services": {
    "apache2": "healthy",
    "mariadb": "healthy",
    "code-server": "healthy"
  }
}
```

### herodev-logs

Exibe logs de um serviço.

**Uso:**
```bash
herodev-logs <serviço> [linhas]
```

**Exemplo:**
```bash
herodev-logs apache2 100
```

### herodev-services

Lista serviços instalados.

**Uso:**
```bash
herodev-services
```

**Retorno:**
```json
{
  "core": ["apache2", "mariadb", "code-server", "phpmyadmin"],
  "optional": ["filebrowser", "redis", "mongodb"]
}
```

### Outros scripts

| Script | Descrição |
|--------|-----------|
| `healthcheck.sh` | Verificação completa de todos os serviços |
| `init-mariadb.sh` | Inicializa banco de dados na primeira execução |
| `backup-db.sh` | Backup do banco de dados MariaDB |
| `restore-db.sh` | Restaura backup do banco de dados |
| `install-wordpress.sh` | Instalação automática do WordPress |
| `check-updates.sh` | Verifica atualizações disponíveis |

---

## Containerfile

O Containerfile define a imagem base do HeroDev.

### Estrutura

```dockerfile
# Base
FROM ubuntu:22.04

# Build Arguments para serviços opcionais
ARG INSTALL_FILEBROWSER=false
ARG INSTALL_REDIS=false
ARG INSTALL_MONGODB=false
ARG INSTALL_NGINX=false
ARG INSTALL_PROMETHEUS=false
ARG INSTALL_GRAFANA=false
```

### Principais seções

1. **BASE**: Pacotes essenciais, systemd, Apache, PHP, MariaDB
2. **NODE**: Node.js 20.x LTS
3. **ELECTRON DEPS**: Dependências para compilar aplicações Electron
4. **WORKSPACE**: Configuração de diretórios de trabalho
5. **PHPMYADMIN**: Interface web para banco de dados
6. **MARIADB INIT**: Scripts de inicialização
7. **HELPER SCRIPTS**: Scripts herodev-*
8. **USER DEV**: Usuário de desenvolvimento com sudo
9. **VSCODE WEB**: code-server com extensões
10. **SERVIÇOS OPCIONAIS**: Instalação condicional baseada em build args

### Volumes definidos

```dockerfile
VOLUME ["/sys/fs/cgroup"]
VOLUME ["/workspace"]
VOLUME ["/home/dev/.config/code-server"]
VOLUME ["/home/dev/.local/share/code-server"]
VOLUME ["/var/lib/mysql"]
```

### Variáveis de ambiente

```dockerfile
ENV HERODEV_VERSION=1.0.0
ENV HERODEV_TYPE=development
ENV WORKSPACE_PATH=/workspace
ENV WWW_PATH=/workspace/www
```

---

## Volumes

### workspace/www

DocumentRoot do Apache. Coloque seus projetos aqui.

**Acesso:** http://localhost:8080/nome-projeto/

### workspace/vsdesktop

Aplicação desktop VSDesktop.

### db

Dados do MariaDB. Persistência completa do banco de dados.

### vscode/config

Arquivo `config.yaml` do code-server.

**Conteúdo padrão:**
```yaml
bind-addr: 0.0.0.0:12777
auth: password
password: dev
cert: false
```

### vscode/data

Extensões e dados do code-server.

---

## Configuração

### Alterar Senha do code-server

Edite `volumes/vscode/config/config.yaml`:

```yaml
bind-addr: 0.0.0.0:12777
auth: password
password: nova_senha
cert: false
```

Para desabilitar autenticação (uso local apenas):

```yaml
auth: none
```

### Alterar Senha do MariaDB

```bash
podman exec -it herodev bash
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'nova_senha';
ALTER USER 'root'@'%' IDENTIFIED BY 'nova_senha';
FLUSH PRIVILEGES;
exit
```

### Modificar portas

**Windows** - Edite `win_start-herodev.bat`:
```batch
-p 80:80            # Apache na porta 80
-p 3307:3306        # MariaDB na porta 3307
```

**macOS** - Edite `mac_start-herodev.sh`:
```bash
-p 80:80            # Apache na porta 80
-p 3307:3306        # MariaDB na porta 3307
```

---

## VSDesktop

Aplicação desktop Electron para gerenciar o HeroDev Container.

### Funcionalidades

- Interface gráfica para gerenciamento do container
- Controle de serviços (start/stop/restart)
- Monitoramento de status em tempo real
- Sistema de abas para serviços web
- Tray icon para acesso rápido
- Temas claro e escuro

### Compilação

**Windows:**
```cmd
win_setup-vsdesktop.bat
```

**macOS:**
```bash
./mac_setup-vsdesktop.sh
```

Ou manualmente dentro do container:
```bash
podman exec -it herodev bash
cd /workspace/vsdesktop
npm install
npm run package:win   # Windows
npm run package:mac_x64   # macOS Intel
npm run package:mac_arm64 # macOS Apple Silicon

exit
```

### Executável

**Windows:**
```
volumes\workspace\vsdesktop\out\vsdesktop-win32-x64\vsdesktop.exe
```

**macOS:**
```
volumes/workspace/vsdesktop/out/vsdesktop-darwin-x64/vsdesktop.app
```

Consulte [volumes/workspace/vsdesktop/README.md](volumes/workspace/vsdesktop/README.md) para documentação completa.

---

## Comandos úteis

### Acessar terminal do container

```bash
podman exec -it herodev bash
```

### Verificar status dos serviços

```bash
systemctl status apache2
systemctl status mariadb
systemctl status code-server
```

### Reiniciar serviço

```bash
systemctl restart apache2
```

### Ver logs

```bash
journalctl -u apache2 -f
journalctl -u mariadb -f
```

### Verificar portas

```bash
netstat -tuln
```

### Informações do container

```bash
herodev-info
```

### Listar projetos

```bash
herodev-projects
```

---

## Segurança

**AMBIENTE DE DESENVOLVIMENTO LOCAL APENAS**

Este projeto foi projetado para desenvolvimento local e usa **credenciais padrão intencionalmente** para ser "ready-to-go" e facilitar o desenvolvimento sem configurações complexas. As senhas estão documentadas porque são necessárias para o funcionamento das ferramentas incluídas.

### Por que as senhas estão expostas?

Este é um ambiente de desenvolvimento local que deve rodar **apenas em localhost**. As credenciais padrão permitem que você:
- Inicie o ambiente sem configurações
- Acesse todos os serviços imediatamente
- Compartilhe o projeto com outros desenvolvedores
- Mantenha consistência entre máquinas

**Use APENAS em rede local/localhost. NUNCA exponha à internet.**

### Credenciais padrão

| Serviço | Usuário | Senha |
|---------|---------|-------|
| MariaDB (root) | root | root |
| code-server | - | dev |
| File Browser | admin | adminadmin123 |
| Mongo Express | admin | admin |
| Grafana | admin | admin |

### Recomendações de segurança

1. **Use APENAS em localhost** - nunca exponha as portas para a internet
2. **Firewall local** - mantenha as portas bloqueadas externamente
3. **Rede confiável** - use apenas em redes privadas/domésticas
4. **Backups seguros** - mantenha backups em local seguro
5. **Não commite** o arquivo `.backup-config` (já está no .gitignore)
6. **Altere senhas** se precisar expor temporariamente (não recomendado)

### Este NÃO é um ambiente de produção

**Nunca use este container em produção.** Ele foi criado para desenvolvimento local rápido, não para segurança ou performance. Para produção:
- Use imagens oficiais otimizadas
- Configure SSL/TLS
- Implemente autenticação robusta
- Siga as melhores práticas de segurança do seu stack

---

## Solução de problemas

### Container não inicia

1. Verifique se Podman Machine está rodando:
```bash
podman machine list
```

2. Inicie a machine:
```bash
podman machine start
```

### Serviço não sobe

1. Verifique logs:
```bash
journalctl -u nome-serviço -n 50
```

2. Reinicie o serviço:
```bash
systemctl restart nome-serviço
```

### Porta já em uso

**Windows:**
```cmd
netstat -ano | findstr :8080
```

**macOS:**
```bash
lsof -i :8080
```

Depois altere a porta no script de start correspondente.

### Erro de permissão em volumes

1. Verifique propriedade dos arquivos:
```bash
ls -la /workspace/www
```

2. Corrija permissões:
```bash
chown -R www-data:www-data /workspace/www
```

### Podman Machine corrompida

**Windows:**
```cmd
win_limpar_vm.bat
win_create-herodev.bat
```

**macOS:**
```bash
./mac_limpar_vm.sh
./mac_create-herodev.sh
```

### Scripts macOS não executam ("permission denied")

Execute:
```bash
chmod +x mac_*.sh
```

---

## Contribuindo

Contribuições são bem-vindas! Por favor, leia [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes sobre o processo de contribuição e padrões de código.

### Como contribuir

1. Fork o projeto
2. Crie um branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'feat: adiciona MinhaFeature'`)
4. Push para o branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para diretrizes completas.

---

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## Suporte

**Importante**: Este é um projeto de código aberto oferecido "como está", sem suporte oficial.

### Recursos

- **Documentação**: Leia o [README.md](README.md) completo
- **Bugs**: Abra uma [issue](https://github.com/herodjou/herodev-container/issues)
- **Sugestões**: Use [discussions](https://github.com/herodjou/herodev-container/discussions)
- **Segurança**: Leia [SECURITY.md](SECURITY.md)

### Comunidade

- Dê uma estrela se este projeto te ajudou!
- Faça fork e crie suas próprias customizações
- Compartilhe com outros desenvolvedores

---

**Desenvolvido com ❤️ para a comunidade de desenvolvedores**


## Workflow de sincronização (OneDrive/iCloud)

Para trabalhar no mesmo ambiente em múltiplas máquinas:

### Máquina de origem

1. Pare o container:
   - **Windows:** `win_stop-herodev.bat`
   - **macOS:** `./mac_stop-herodev.sh`

2. Execute o backup:
   - **Windows:** `win_backup-herodev.bat`
   - **macOS:** `./mac_backup-herodev.sh`

3. Escolha o destino na pasta sincronizada (OneDrive, iCloud, etc.)

4. Aguarde sincronização completar

### Máquina de destino

1. Copie `backup-herodev.zip` da pasta sincronizada para o diretório do projeto

2. Extraia o conteúdo (substituindo arquivos existentes)

3. Inicie o container:
   - **Windows:** `win_start-herodev.bat`
   - **macOS:** `./mac_start-herodev.sh`

> **Dica:** O backup usa nome fixo `backup-herodev.zip` para facilitar sincronização automática. O arquivo mais recente sempre substitui o anterior
