#!/bin/bash
set -e

DATADIR="/var/lib/mysql/mysql"

if [ ! -d "$DATADIR" ]; then
    echo "[init-mariadb] Data directory vazio. Inicializando banco..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    chown -R mysql:mysql /var/lib/mysql

    echo "[init-mariadb] Configurando root com senha 'root'..."
    mysqld_safe --skip-networking &
    pid="$!"
    sleep 5

    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;"
    mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY 'root'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

    kill "$pid"
    wait "$pid" 2>/dev/null || true
else
    echo "[init-mariadb] Data directory já existe. Pulando init."
fi
