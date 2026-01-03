#!/bin/bash
# Instalação rápida do WordPress
# Uso: ./install-wordpress.sh <nome-do-projeto>

set -e

if [ -z "$1" ]; then
    echo "Uso: ./install-wordpress.sh <nome-do-projeto>"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_DIR="/workspace/www/$PROJECT_NAME"

if [ -d "$PROJECT_DIR" ]; then
    echo "Erro: Diretório $PROJECT_DIR já existe!"
    exit 1
fi

echo "==========================================
"
echo "       INSTALAÇÃO WORDPRESS"
echo "==========================================
"
echo "Projeto: $PROJECT_NAME"
echo "Diretório: $PROJECT_DIR"
echo ""

# Download WordPress
echo "1. Baixando WordPress..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
curl -O https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# Criar banco de dados
echo ""
echo "2. Criando banco de dados..."
DB_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
DB_USER="$DB_NAME"
DB_PASS=$(openssl rand -base64 12)

mysql -u root -proot << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Configurar wp-config.php
echo ""
echo "3. Configurando WordPress..."
cp wp-config-sample.php wp-config.php

# Gerar salt keys
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Atualizar wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASS/" wp-config.php
sed -i "s/localhost/127.0.0.1/" wp-config.php

# Inserir salt keys
awk '/AUTH_KEY/{f=1} f && /NONCE_SALT/{print; print "'"$SALT"'"; f=0; next} !f' wp-config.php > wp-config-new.php
mv wp-config-new.php wp-config.php

# Ajustar permissões
chown -R www-data:www-data "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

echo ""
echo "==========================================
"
echo "       WORDPRESS INSTALADO!"
echo "==========================================
"
echo ""
echo "Acesse: http://localhost:8080/$PROJECT_NAME"
echo ""
echo "Credenciais do Banco:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""
echo "IMPORTANTE: Guarde essas credenciais!"
echo "==========================================
"

# Salvar credenciais em arquivo
cat > "$PROJECT_DIR/.herodev-credentials" << EOF
# Credenciais do WordPress - $PROJECT_NAME
# Gerado em: $(date)

DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_HOST=127.0.0.1

# Acesso Web
URL=http://localhost:8080/$PROJECT_NAME
EOF

chmod 600 "$PROJECT_DIR/.herodev-credentials"

echo ""
echo "Credenciais salvas em: $PROJECT_DIR/.herodev-credentials"
