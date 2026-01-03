#!/bin/bash
# herodev-info - Retorna informações do sistema em JSON

cat << EOF
{
  "hostname": "$(hostname)",
  "os": "$(lsb_release -ds 2>/dev/null || echo "Ubuntu 22.04")",
  "kernel": "$(uname -r)",
  "php_version": "$(php -v 2>/dev/null | head -n1 | cut -d' ' -f2 || echo 'N/A')",
  "node_version": "$(node -v 2>/dev/null || echo 'N/A')",
  "npm_version": "$(npm -v 2>/dev/null || echo 'N/A')",
  "python_version": "$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'N/A')",
  "mysql_version": "$(mysql --version 2>/dev/null | cut -d' ' -f3 | cut -d'-' -f1 || echo 'N/A')",
  "apache_version": "$(apache2 -v 2>/dev/null | head -n1 | cut -d'/' -f2 | cut -d' ' -f1 || echo 'N/A')",
  "uptime": "$(uptime -p || echo 'N/A')",
  "load_average": "$(cat /proc/loadavg | cut -d' ' -f1-3 || echo 'N/A')",
  "memory_total": "$(free -m | awk 'NR==2{print $2}' || echo '0')",
  "memory_used": "$(free -m | awk 'NR==2{print $3}' || echo '0')",
  "disk_total": "$(df -h / | awk 'NR==2{print $2}' || echo 'N/A')",
  "disk_used": "$(df -h / | awk 'NR==2{print $3}' || echo 'N/A')",
  "disk_percent": "$(df -h / | awk 'NR==2{print $5}' | tr -d '%' || echo '0')"
}
EOF
