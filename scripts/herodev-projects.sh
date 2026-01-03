#!/bin/bash
# herodev-projects - Scanner de projetos no workspace com detecção de framework

WORKSPACE=${1:-/workspace/www}

# Função para detectar framework PHP
detect_php_framework() {
    local DIR=$1
    
    if [ -f "$DIR/artisan" ] && grep -q "laravel/framework" "$DIR/composer.json" 2>/dev/null; then
        echo "Laravel"
    elif [ -f "$DIR/wp-config.php" ] && [ -d "$DIR/wp-content" ]; then
        echo "WordPress"
    elif [ -f "$DIR/symfony.lock" ] || grep -q "symfony/symfony" "$DIR/composer.json" 2>/dev/null; then
        echo "Symfony"
    elif [ -f "$DIR/index.php" ]; then
        echo "PHP"
    else
        echo ""
    fi
}

# Função para detectar framework Node.js
detect_node_framework() {
    local DIR=$1
    
    if [ -f "$DIR/next.config.js" ] || [ -f "$DIR/next.config.mjs" ]; then
        echo "Next.js"
    elif [ -f "$DIR/nest-cli.json" ]; then
        echo "NestJS"
    elif grep -q '"react"' "$DIR/package.json" 2>/dev/null; then
        if grep -q '"gatsby"' "$DIR/package.json" 2>/dev/null; then
            echo "Gatsby"
        else
            echo "React"
        fi
    elif grep -q '"vue"' "$DIR/package.json" 2>/dev/null; then
        if grep -q '"nuxt"' "$DIR/package.json" 2>/dev/null; then
            echo "Nuxt"
        else
            echo "Vue.js"
        fi
    elif grep -q '"express"' "$DIR/package.json" 2>/dev/null; then
        echo "Express"
    elif grep -q '"@angular/core"' "$DIR/package.json" 2>/dev/null; then
        echo "Angular"
    elif grep -q '"svelte"' "$DIR/package.json" 2>/dev/null; then
        echo "Svelte"
    else
        echo "Node.js"
    fi
}

# Função para detectar framework Python
detect_python_framework() {
    local DIR=$1
    
    if [ -f "$DIR/manage.py" ] && [ -f "$DIR/settings.py" ]; then
        echo "Django"
    elif grep -q "flask" "$DIR/requirements.txt" 2>/dev/null; then
        echo "Flask"
    elif grep -q "fastapi" "$DIR/requirements.txt" 2>/dev/null; then
        echo "FastAPI"
    else
        echo "Python"
    fi
}

# Função para verificar se tem banco de dados
has_database() {
    local DIR=$1
    
    # Verifica .env com DB_
    if [ -f "$DIR/.env" ] && grep -q "DB_" "$DIR/.env" 2>/dev/null; then
        echo "true"
        return
    fi
    
    # Verifica arquivos de configuração comuns
    local DB_FILES=(
        "$DIR/wp-config.php"
        "$DIR/config/database.php"
        "$DIR/.env.local"
        "$DIR/settings.py"
        "$DIR/knexfile.js"
        "$DIR/ormconfig.json"
        "$DIR/database.json"
    )
    
    for FILE in "${DB_FILES[@]}"; do
        if [ -f "$FILE" ]; then
            echo "true"
            return
        fi
    done
    
    echo "false"
}

# Função para verificar Git
check_git() {
    local DIR=$1
    
    if [ -d "$DIR/.git" ]; then
        local REMOTE=$(cd "$DIR" && git config --get remote.origin.url 2>/dev/null || echo "")
        echo "true|$REMOTE"
    else
        echo "false|"
    fi
}

# Main
echo "["
FIRST=true

if [ ! -d "$WORKSPACE" ]; then
    echo "]"
    exit 0
fi

for DIR in "$WORKSPACE"/*; do
    if [ -d "$DIR" ]; then
        NAME=$(basename "$DIR")
        MTIME=$(stat -c %Y "$DIR" 2>/dev/null || echo "0")
        
        # Detectar linguagem
        LANG="unknown"
        FRAMEWORK=""
        
        if [ -f "$DIR/package.json" ]; then
            LANG="node"
            FRAMEWORK=$(detect_node_framework "$DIR")
        elif [ -f "$DIR/composer.json" ] || ls "$DIR"/*.php >/dev/null 2>&1; then
            LANG="php"
            FRAMEWORK=$(detect_php_framework "$DIR")
        elif [ -f "$DIR/requirements.txt" ] || [ -f "$DIR/pyproject.toml" ]; then
            LANG="python"
            FRAMEWORK=$(detect_python_framework "$DIR")
        elif ls "$DIR"/*.html >/dev/null 2>&1; then
            LANG="static"
            FRAMEWORK="HTML"
        fi
        
        # Verifica banco de dados
        HAS_DB=$(has_database "$DIR")
        
        # Verifica Git
        GIT_INFO=$(check_git "$DIR")
        IS_GIT=$(echo "$GIT_INFO" | cut -d'|' -f1)
        GIT_REMOTE=$(echo "$GIT_INFO" | cut -d'|' -f2)
        
        # Output JSON
        [ "$FIRST" = false ] && echo ","
        FIRST=false
        
        echo "  {"
        echo "    \"name\": \"$NAME\","
        echo "    \"path\": \"$DIR\","
        echo "    \"language\": \"$LANG\","
        echo "    \"framework\": \"$FRAMEWORK\","
        echo "    \"lastModified\": $MTIME,"
        echo "    \"hasDatabase\": $HAS_DB,"
        echo "    \"isGitRepo\": \"$IS_GIT\","
        echo -n "    \"gitRemote\": \"$GIT_REMOTE\""
        echo ""
        echo -n "  }"
    fi
done

echo ""
echo "]"
