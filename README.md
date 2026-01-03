# HeroDev Container

Ambiente de desenvolvimento completo e portável baseado em containers Linux, executável em Windows via Podman. Inclui Apache, PHP, MariaDB, Node.js, Python e VS Code web em um único container com systemd habilitado.

## Índice

- [Visão geral](#visão-geral)
- [Requisitos](#requisitos)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Instalação](#instalação)
- [Uso](#uso)
- [Serviços](#serviços)
- [Scripts BAT](#scripts-bat)
- [Scripts Shell](#scripts-shell)
- [Containerfile](#containerfile)
- [Volumes](#volumes)
- [Configuração](#configuracao)
- [VSDesktop](#vsdesktop)
- [Comandos úteis](#comandos-uteis)
- [Solução de problemas](#solucao-de-problemas)

---

## Visão geral

O HeroDev Container e um ambiente de desenvolvimento all-in-one que pode ser executado de qualquer local, incluindo drives externos. Todos os dados (banco de dados, projetos, configurações) sao persistidos em volumes locais, garantindo portabilidade total.

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

### Sistema Operacional
- Windows 10/11 com WSL2 habilitado

### Software
- Podman Desktop 4.0+ ou Podman CLI

### Hardware
- RAM: 4GB mínimo (8GB recomendado)
- Disco: 10GB espaço livre

### Instalação do Podman

1. Download em: https://podman.io/getting-started/installation
2. Executar instalador
3. Reiniciar o sistema

---

## Estrutura do projeto

```
herodev-cont/
├── Containerfile              # Definição da imagem Docker/Podman
├── create-herodev.bat         # Build da imagem e criação inicial
├── start-herodev.bat          # Inicia container e serviços
├── stop-herodev.bat           # Para container e serviços
├── limpar_vm.bat              # Remove Podman Machine completamente
├── setup-vsdesktop.bat        # Compila VSDesktop
├── start.sh                   # Script de inicialização interno
├── scripts/                   # Scripts auxiliares do container
│   ├── backup-db.sh
│   ├── check-updates.sh
│   ├── healthcheck.sh
│   ├── herodev-info.sh
│   ├── herodev-projects.sh
│   ├── herodev-status.sh
│   ├── init-mariadb.sh
│   ├── install-wordpress.sh
│   └── restore-db.sh
└── volumes/                   # Dados persistentes
    ├── workspace/
    │   ├── www/               # DocumentRoot do Apache
    │   └── vsdesktop/         # Aplicação desktop
    ├── db/                    # Dados do MariaDB
    └── vscode/
        ├── config/            # Configurações do code-server
        └── data/              # Dados do code-server
```

---

## Instalação

### Primeira execução

1. Clone ou copie o repositório:
```cmd
git clone https://github.com/herodjou/herodev-container.git
cd herodev-cont
```

2. Execute o script de criação:
```cmd
create-herodev.bat
```

O script irá:
- Solicitar quais serviços opcionais instalar
- Inicializar a Podman Machine (se necessário)
- Construir a imagem `herodev-all`
- Executar automaticamente o `start-herodev.bat`

### Serviços opcionais no Build

Durante a execução de `create-herodev.bat`, serão oferecidas as seguintes opções:

| Serviço | Descrição |
|---------|-----------|
| File Browser | Gerenciador de arquivos web |
| Redis | Cache em memoria e filas |
| MongoDB + Mongo Express | Banco NoSQL com interface web |
| Nginx | Servidor web alternativo |
| Prometheus + Grafana | Monitoramento e dashboards |

---

## Uso

### Iniciar o ambiente

```cmd
start-herodev.bat
```

Ações executadas:
1. Cria estrutura de pastas se necessário
2. Inicia Podman Machine
3. Inicia ou cria container herodev
4. Inicia serviços core (Apache, MariaDB, code-server)
5. Inicia serviços opcionais instalados
6. Oferece opção de executar GUI (VSDesktop)

### Parar o ambiente

```cmd
stop-herodev.bat
```

Ações executadas:
1. Para serviços Apache e MariaDB
2. Para o container
3. Para a Podman Machine

### Limpar instalação

```cmd
limpar_vm.bat
```

Remove completamente:
- Podman Machine
- Conexões do sistema

---

## Serviços

### Serviços Core (Sempre disponíveis)

| Serviço | URL | Porta | Credenciais |
|---------|-----|-------|-------------|
| Apache | http://localhost:8080 | 8080 | - |
| phpMyAdmin | http://localhost:8080/phpmyadmin | 8080 | root / root |
| VS Code Server | http://localhost:12777 | 12777 | Senha: (verificar em `vscode/config/config.yaml`) |
| MariaDB | localhost:3306 | 3306 | root / root |

### Serviços opcionais

| Serviço | URL | Porta | Credenciais |
|---------|-----|-------|-------------|
| File Browser | http://localhost:8081 | 8081 | admin / adminadmin123 |
| Redis | localhost:6379 | 6379 | - |
| MongoDB | localhost:27017 | 27017 | - |
| Mongo Express | http://localhost:8082 | 8082 | admin / admin |
| Nginx | http://localhost:8083 | 8083 | - |
| Prometheus | http://localhost:9090 | 9090 | - |
| Grafana | http://localhost:3000 | 3000 | admin / admin |

---

## Scripts BAT

### create-herodev.bat

Responsável pelo build inicial da imagem.

**Funcionalidades:**
- Solicita seleção de serviços opcionais interativamente
- Inicializa Podman Machine se inexistente
- Executa `podman build` com argumentos selecionados
- Chama `start-herodev.bat` ao finalizar

**Build Arguments suportados:**
```
--build-arg INSTALL_FILEBROWSER=true
--build-arg INSTALL_REDIS=true
--build-arg INSTALL_MONGODB=true
--build-arg INSTALL_NGINX=true
--build-arg INSTALL_PROMETHEUS=true
--build-arg INSTALL_GRAFANA=true
```

### start-herodev.bat

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

### stop-herodev.bat

Para o ambiente de forma segura.

**Funcionalidades:**
- Para serviços internos (Apache, MariaDB)
- Para o container
- Para a Podman Machine

### setup-vsdesktop.bat

Compila a aplicação VSDesktop.

**Funcionalidades:**
- Verifica se container está rodando
- Clona repositório se necessário
- Instala dependências npm
- Compila aplicação para Windows (x64)
- Oferece execução após build

### limpar_vm.bat

Remove completamente a instalação do Podman Machine.

**Comandos executados:**
```cmd
podman machine stop
podman machine rm -f
podman system connection rm podman-machine-default
podman system connection rm podman-machine-default-root
```

---

## Scripts Shell

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

### healthcheck.sh

Executa verificação completa de todos os serviços com output formatado.

**Uso:**
```bash
healthcheck.sh
```

### init-mariadb.sh

Inicializa banco de dados MariaDB na primeira execução.

**Funcionalidades:**
- Cria diretórios necessários
- Inicializa sistema de banco
- Define senha root
- Configura permissões

### backup-db.sh

Realiza backup do banco de dados.

### restore-db.sh

Restaura backup do banco de dados.

### install-wordpress.sh

Instala WordPress automaticamente.

### check-updates.sh

Verifica atualizações disponíveis.

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

Edite `start-herodev.bat` e altere as flags `-p`:

```batch
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

```cmd
setup-vsdesktop.bat
```

Ou manualmente:

```cmd
podman exec -it herodev bash
cd /workspace/vsdesktop
npm install
npm run package:win
exit
```

### Executável

```
volumes\workspace\vsdesktop\out\vsdesktop-win32-x64\vsdesktop.exe
```

Consulte [volumes/workspace/vsdesktop/README.md](volumes/workspace/vsdesktop/README.md) para documentacao completa.

---

## Comandos úteis

### Acessar terminal do container

```cmd
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

## Solução de problemas

### Container não inicia

1. Verifique se Podman Machine está rodando:
```cmd
podman machine list
```

2. Inicie a machine:
```cmd
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

1. Identifique processo usando a porta (Windows):
```cmd
netstat -ano | findstr :8080
```

2. Altere a porta em `start-herodev.bat`

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

Execute:
```cmd
limpar_vm.bat
```

Depois recrie com:
```cmd
create-herodev.bat
```
