#!/bin/bash
# Verifica atualizações disponíveis para componentes do HeroDev
# Uso: ./check-updates.sh

echo "==========================================
"
echo "       VERIFICAÇÃO DE ATUALIZAÇÕES"
echo "==========================================
"
echo ""

check_version() {
    NAME=$1
    CURRENT=$2
    COMMAND=$3
    
    echo "► $NAME"
    echo "  Versão atual: $CURRENT"
    echo "  Verificando atualizações disponíveis..."
    eval "$COMMAND"
    echo ""
}

# PHP
PHP_CURRENT=$(php -v | head -n1 | cut -d ' ' -f2 | cut -d '-' -f1)
check_version "PHP" "$PHP_CURRENT" "apt-cache policy php | grep Candidate | awk '{print \$2}'"

# Node.js
NODE_CURRENT=$(node -v)
check_version "Node.js" "$NODE_CURRENT" "curl -s https://nodejs.org/dist/latest-v20.x/ | grep -oP 'node-v\K[0-9]+\.[0-9]+\.[0-9]+' | head -n1"

# Python
PYTHON_CURRENT=$(python3 --version | cut -d ' ' -f2)
check_version "Python" "$PYTHON_CURRENT" "apt-cache policy python3 | grep Candidate | awk '{print \$2}'"

# MariaDB
MYSQL_CURRENT=$(mysql --version | cut -d ' ' -f3 | cut -d ',' -f1)
check_version "MariaDB" "$MYSQL_CURRENT" "apt-cache policy mariadb-server | grep Candidate | awk '{print \$2}'"

# Apache
APACHE_CURRENT=$(apache2 -v | head -n1 | cut -d '/' -f2 | cut -d ' ' -f1)
check_version "Apache" "$APACHE_CURRENT" "apt-cache policy apache2 | grep Candidate | awk '{print \$2}'"

# code-server
if command -v code-server &> /dev/null; then
    CODESERVER_CURRENT=$(code-server --version | head -n1)
    check_version "code-server" "$CODESERVER_CURRENT" "curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep tag_name | cut -d '\"' -f4"
fi

# Redis (se instalado)
if command -v redis-server &> /dev/null; then
    REDIS_CURRENT=$(redis-server --version | awk '{print $3}' | cut -d '=' -f2)
    check_version "Redis" "$REDIS_CURRENT" "apt-cache policy redis-server | grep Candidate | awk '{print \$2}'"
fi

# MongoDB (se instalado)
if command -v mongod &> /dev/null; then
    MONGO_CURRENT=$(mongod --version | grep "db version" | awk '{print $3}' | cut -d 'v' -f2)
    check_version "MongoDB" "$MONGO_CURRENT" "apt-cache policy mongodb-org | grep Candidate | awk '{print \$2}'"
fi

# Nginx (se instalado)
if command -v nginx &> /dev/null; then
    NGINX_CURRENT=$(nginx -v 2>&1 | cut -d '/' -f2)
    check_version "Nginx" "$NGINX_CURRENT" "apt-cache policy nginx | grep Candidate | awk '{print \$2}'"
fi

echo "==========================================
"
echo ""
echo "Para atualizar os pacotes, execute:"
echo ""
echo "  apt update"
echo "  apt upgrade -y"
echo ""
echo "ATENÇÃO: Algumas atualizações podem requerer rebuild da imagem."
echo "==========================================
"
