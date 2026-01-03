#!/bin/bash
# Healthcheck completo do ambiente HeroDev
# Uso: ./healthcheck.sh

echo "==========================================
"
echo "       HERODEV HEALTHCHECK"
echo "==========================================
"
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    SERVICE=$1
    DISPLAY_NAME=$2
    
    if systemctl is-active --quiet "$SERVICE"; then
        echo -e "${GREEN}✓${NC} $DISPLAY_NAME: Running"
        return 0
    else
        echo -e "${RED}✗${NC} $DISPLAY_NAME: Stopped"
        return 1
    fi
}

check_port() {
    PORT=$1
    SERVICE=$2
    
    if netstat -tuln | grep -q ":$PORT "; then
        echo -e "${GREEN}✓${NC} Port $PORT ($SERVICE): Open"
        return 0
    else
        echo -e "${RED}✗${NC} Port $PORT ($SERVICE): Closed"
        return 1
    fi
}

# Verificar serviços core
echo "SERVIÇOS CORE:"
check_service "apache2" "Apache"
check_service "mariadb" "MariaDB"
check_service "code-server" "VS Code Server"

echo ""
echo "SERVIÇOS OPCIONAIS:"
[ -f /usr/local/bin/filebrowser ] && check_service "filebrowser" "File Browser"
[ -f /usr/bin/redis-server ] && check_service "redis-server" "Redis"
[ -f /usr/bin/mongod ] && check_service "mongod" "MongoDB"
[ -f /usr/bin/mongo-express ] && check_service "mongo-express" "Mongo Express"
[ -f /usr/sbin/nginx ] && check_service "nginx" "Nginx"
[ -f /usr/local/bin/prometheus ] && check_service "prometheus" "Prometheus"
[ -f /usr/sbin/grafana-server ] && check_service "grafana-server" "Grafana"

echo ""
echo "PORTAS:"
check_port "80" "Apache"
check_port "3306" "MariaDB"
check_port "12777" "code-server"
[ -f /usr/local/bin/filebrowser ] && check_port "8081" "File Browser"
[ -f /usr/bin/redis-server ] && check_port "6379" "Redis"
[ -f /usr/bin/mongod ] && check_port "27017" "MongoDB"
[ -f /usr/bin/mongo-express ] && check_port "8082" "Mongo Express"
[ -f /usr/sbin/nginx ] && check_port "8083" "Nginx"
[ -f /usr/local/bin/prometheus ] && check_port "9090" "Prometheus"
[ -f /usr/sbin/grafana-server ] && check_port "3000" "Grafana"

echo ""
echo "RECURSOS:"
# Memória
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf("%.1f"), $3/$2 * 100}')
echo "  Memória: $MEM_USED / $MEM_TOTAL ($MEM_PERCENT%)"

# Disco
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_PERCENT=$(df / | awk 'NR==2 {print $5}')
echo "  Disco: $DISK_USED / $DISK_TOTAL ($DISK_PERCENT)"

# Uptime
UPTIME=$(uptime -p)
echo "  Uptime: $UPTIME"

echo ""
echo "VERSÕES:"
echo "  PHP: $(php -v | head -n1 | cut -d ' ' -f2)"
echo "  Node: $(node -v)"
echo "  Python: $(python3 --version | cut -d ' ' -f2)"
echo "  MySQL: $(mysql --version | cut -d ' ' -f3 | cut -d ',' -f1)"
echo "  Apache: $(apache2 -v | head -n1 | cut -d '/' -f2 | cut -d ' ' -f1)"

echo ""
echo "WORKSPACE:"
WWW_SIZE=$(du -sh /workspace/www 2>/dev/null | cut -f1 || echo "0")
PROJECT_COUNT=$(find /workspace/www -maxdepth 1 -type d | tail -n +2 | wc -l)
echo "  Projetos: $PROJECT_COUNT"
echo "  Tamanho: $WWW_SIZE"

# Verificar banco de dados
echo ""
echo "BANCOS DE DADOS:"
DB_COUNT=$(mysql -u root -proot -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | wc -l)
echo "  Total: $DB_COUNT"
mysql -u root -proot -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|performance_schema\|mysql\|sys" | while read db; do
    SIZE=$(mysql -u root -proot -e "SELECT SUM(data_length + index_length) / 1024 / 1024 AS 'Size' FROM information_schema.tables WHERE table_schema='$db';" | tail -n1)
    echo "    - $db: ${SIZE}MB"
done

echo ""
echo "==========================================
"
echo "Healthcheck concluído!"
echo "==========================================
"
