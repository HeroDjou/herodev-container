FROM ubuntu:22.04

# Build arguments para instalação opcional
ARG INSTALL_FILEBROWSER=false
ARG INSTALL_REDIS=false
ARG INSTALL_MONGODB=false
ARG INSTALL_NGINX=false
ARG INSTALL_PROMETHEUS=false
ARG INSTALL_GRAFANA=false

ENV DEBIAN_FRONTEND=noninteractive

# ---------------- BASE ----------------
RUN apt update && apt install -y \
    systemd systemd-sysv \
    apache2 \
    php php-cli php-mysql php-curl php-gd php-mbstring php-xml php-zip php-fpm \
    mariadb-server \
    curl wget unzip git ca-certificates gnupg lsb-release \
    python3 python3-pip python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ---------------- NODE ----------------
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt install -y nodejs

# ---------------- ELECTRON DEPS ----------------
RUN apt update && apt install -y \
    libnspr4 libgbm1 libnss3 libatk1.0-0 libcups2 libxss1 libx11-xcb1 \
    libxcomposite1 libxrandr2 libgtk-3-0 libasound2 \
    && rm -rf /var/lib/apt/lists/*

# ---------------- WORKSPACE / WWW ----------------
RUN mkdir -p /workspace/www \
 && rm -rf /var/www/html \
 && ln -s /workspace/www /var/www/html \
 && chown -R www-data:www-data /workspace/www

# ---------------- PHPMYADMIN ----------------
RUN curl -L https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
    | tar zx -C /var/www/ \
    && mv /var/www/phpMyAdmin-* /var/www/phpmyadmin \
    && chown -R www-data:www-data /var/www/phpmyadmin

RUN printf "Alias /phpmyadmin /var/www/phpmyadmin\n\
<Directory /var/www/phpmyadmin>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>\n" \
> /etc/apache2/conf-available/phpmyadmin.conf \
&& a2enconf phpmyadmin

# ---------------- MARIADB INIT ----------------
COPY scripts/init-mariadb.sh /usr/local/bin/init-mariadb.sh
RUN sed -i 's/\r$//' /usr/local/bin/init-mariadb.sh \
 && chmod +x /usr/local/bin/init-mariadb.sh

RUN mkdir -p /etc/systemd/system/mariadb.service.d \
 && printf "[Service]\nExecStartPre=/usr/local/bin/init-mariadb.sh\n" \
    > /etc/systemd/system/mariadb.service.d/init.conf

# ---------------- HERODEV HELPER SCRIPTS ----------------
COPY scripts/herodev-status.sh /usr/local/bin/herodev-status
COPY scripts/herodev-info.sh /usr/local/bin/herodev-info
COPY scripts/herodev-projects.sh /usr/local/bin/herodev-projects
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY scripts/check-updates.sh /usr/local/bin/check-updates.sh

RUN sed -i 's/\r$//' /usr/local/bin/herodev-status \
 && sed -i 's/\r$//' /usr/local/bin/herodev-info \
 && sed -i 's/\r$//' /usr/local/bin/herodev-projects \
 && sed -i 's/\r$//' /usr/local/bin/healthcheck.sh \
 && sed -i 's/\r$//' /usr/local/bin/check-updates.sh \
 && chmod +x /usr/local/bin/herodev-* \
 && chmod +x /usr/local/bin/healthcheck.sh \
 && chmod +x /usr/local/bin/check-updates.sh

# ---------------- USER DEV ----------------
RUN useradd -m dev \
 && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ---------------- VSCODE WEB ----------------
RUN curl -fsSL https://code-server.dev/install.sh | sh

RUN mkdir -p \
    /workspace \
    /home/dev/.config/code-server \
    /home/dev/.local/share/code-server \
 && chown -R dev:dev /workspace /home/dev

RUN printf "bind-addr: 0.0.0.0:12777\nauth: password\npassword: dev\ncert: false\n" \
    > /home/dev/.config/code-server/config.yaml

# -------- EXTENSÕES VSCODE --------
RUN code-server --install-extension ms-python.python \
&& code-server --install-extension MS-CEINTL.vscode-language-pack-pt-BR

# ---------------- SYSTEMD CODE-SERVER ----------------
RUN printf "[Unit]\nDescription=VS Code Web\nAfter=network.target\n\n[Service]\nUser=dev\nExecStart=/usr/bin/code-server --bind-addr 0.0.0.0:12777 /workspace\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n" \
    > /etc/systemd/system/code-server.service

# ============================================================
# SERVIÇOS OPCIONAIS (via build args)
# ============================================================

# ---------------- FILE BROWSER ----------------
RUN if [ "$INSTALL_FILEBROWSER" = "true" ]; then \
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash && \
    mkdir -p /etc/filebrowser && \
    filebrowser config init --address=0.0.0.0 --port=8081 --database=/etc/filebrowser/database.db --root=/workspace && \
    filebrowser users add admin adminadmin123 --perm.admin --database=/etc/filebrowser/database.db && \
    printf "[Unit]\nDescription=File Browser\nAfter=network.target\n\n[Service]\nExecStart=/usr/local/bin/filebrowser --database /etc/filebrowser/database.db\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/filebrowser.service; \
    fi

# ---------------- REDIS ----------------
RUN if [ "$INSTALL_REDIS" = "true" ]; then \
    apt update && apt install -y redis-server && rm -rf /var/lib/apt/lists/* && \
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf; \
    fi

# ---------------- MONGODB ----------------
RUN if [ "$INSTALL_MONGODB" = "true" ]; then \
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg && \
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list && \
    apt update && apt install -y mongodb-org && rm -rf /var/lib/apt/lists/*; \
    fi

# ---------------- MONGO EXPRESS (UI para MongoDB) ----------------
RUN if [ "$INSTALL_MONGODB" = "true" ]; then \
    npm install -g mongo-express@latest --legacy-peer-deps && \
    mkdir -p /etc/mongo-express && \
    printf "mongo:\n  host: \"localhost\"\n  port: 27017\n  adminUsername: \"\"\n  adminPassword: \"\"\nsite:\n  host: \"0.0.0.0\"\n  port: 8082\n  cookieSecret: \"herodev\"\n  sessionSecret: \"herodev\"\n  cookieKeyName: \"mongo-express\"\n  sessSecret: \"herodev\"\n" > /etc/mongo-express/config.yaml && \
    printf "[Unit]\nDescription=Mongo Express\nAfter=mongod.service\n\n[Service]\nUser=dev\nWorkingDirectory=/usr/lib/node_modules/mongo-express\nEnvironment=\"ME_CONFIG_MONGODB_SERVER=localhost\"\nEnvironment=\"ME_CONFIG_MONGODB_PORT=27017\"\nEnvironment=\"ME_CONFIG_MONGODB_ENABLE_ADMIN=true\"\nEnvironment=\"ME_CONFIG_BASICAUTH_USERNAME=admin\"\nEnvironment=\"ME_CONFIG_BASICAUTH_PASSWORD=admin\"\nEnvironment=\"ME_CONFIG_SITE_BASEURL=/\"\nExecStart=/usr/bin/node /usr/lib/node_modules/mongo-express/app.js\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/mongo-express.service; \
    fi

# ---------------- NGINX ----------------
RUN if [ "$INSTALL_NGINX" = "true" ]; then \
    apt update && apt install -y nginx && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /workspace/www && \
    echo '<!DOCTYPE html><html><head><title>NGINX - HeroDev</title></head><body><h1>NGINX funcionando!</h1><p>Coloque seus arquivos em /workspace/www</p></body></html>' > /workspace/www/index.html && \
    printf "server {\n    listen 8083;\n    root /workspace/www;\n    index index.html index.htm index.php;\n    server_name _;\n    autoindex on;\n    location ~ \\.php$ {\n        include snippets/fastcgi-php.conf;\n        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;\n    }\n}\n" > /etc/nginx/sites-available/herodev && \
    ln -sf /etc/nginx/sites-available/herodev /etc/nginx/sites-enabled/ && \
    rm -f /etc/nginx/sites-enabled/default; \
    fi

# ---------------- PROMETHEUS ----------------
RUN if [ "$INSTALL_PROMETHEUS" = "true" ]; then \
    useradd --no-create-home --shell /bin/false prometheus && \
    PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
    curl -L https://github.com/prometheus/prometheus/releases/latest/download/prometheus-${PROM_VERSION}.linux-amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/prometheus-${PROM_VERSION}.linux-amd64/prometheus /usr/local/bin/ && \
    mv /tmp/prometheus-${PROM_VERSION}.linux-amd64/promtool /usr/local/bin/ && \
    rm -rf /tmp/prometheus-${PROM_VERSION}.linux-amd64 && \
    mkdir -p /etc/prometheus /var/lib/prometheus && \
    chown prometheus:prometheus /var/lib/prometheus && \
    printf "global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: 'prometheus'\n    static_configs:\n      - targets: ['localhost:9090']\n  - job_name: 'node'\n    static_configs:\n      - targets: ['localhost:9100']\n" > /etc/prometheus/prometheus.yml && \
    printf "[Unit]\nDescription=Prometheus\nAfter=network.target\n\n[Service]\nUser=prometheus\nExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n" > /etc/systemd/system/prometheus.service; \
    fi

# ---------------- GRAFANA ----------------
RUN if [ "$INSTALL_GRAFANA" = "true" ]; then \
    apt update && apt install -y software-properties-common && \
    curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /usr/share/keyrings/grafana.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list && \
    apt update && apt install -y grafana && rm -rf /var/lib/apt/lists/*; \
    fi

# ============================================================
# CENTRAL HERODEV INTEGRATION
# ============================================================

# Helper scripts para comunicação com Central HeroDev

# Script de status de serviço (retorna JSON)
RUN printf '#!/bin/bash\n\
SERVICE=$1\n\
if [ -z "$SERVICE" ]; then\n\
    echo "Usage: herodev-status <service-name>"\n\
    exit 1\n\
fi\n\
if systemctl is-active --quiet $SERVICE; then\n\
    STATUS="running"\n\
    PID=$(systemctl show -p MainPID --value $SERVICE)\n\
    UPTIME=$(systemctl show -p ActiveEnterTimestamp --value $SERVICE)\n\
    echo "{\\"service\\":\\"$SERVICE\\",\\"status\\":\\"$STATUS\\",\\"pid\\":$PID,\\"uptime\\":\\"$UPTIME\\"}"\n\
else\n\
    echo "{\\"service\\":\\"$SERVICE\\",\\"status\\":\\"stopped\\",\\"pid\\":null,\\"uptime\\":null}"\n\
fi\n' > /usr/local/bin/herodev-status && chmod +x /usr/local/bin/herodev-status

# Script de informações do container (retorna JSON)
RUN printf '#!/bin/bash\n\
cat << EOF\n\
{\n\
  "hostname": "$(hostname)",\n\
  "os": "$(lsb_release -ds 2>/dev/null || echo Unknown)",\n\
  "kernel": "$(uname -r)",\n\
  "php_version": "$(php -v 2>/dev/null | head -n1 | cut -d \" \" -f2 || echo N/A)",\n\
  "node_version": "$(node -v 2>/dev/null || echo N/A)",\n\
  "python_version": "$(python3 --version 2>/dev/null | cut -d \" \" -f2 || echo N/A)",\n\
  "mysql_version": "$(mysql --version 2>/dev/null | cut -d \" \" -f3 || echo N/A)",\n\
  "apache_version": "$(apache2 -v 2>/dev/null | head -n1 | cut -d/ -f2 | cut -d \" \" -f1 || echo N/A)",\n\
  "uptime": "$(uptime -p 2>/dev/null || echo N/A)"\n\
}\n\
EOF\n' > /usr/local/bin/herodev-info && chmod +x /usr/local/bin/herodev-info

# Script de listagem de projetos com detecção (retorna JSON)
RUN printf '#!/bin/bash\n\
WORKSPACE=${1:-/workspace/www}\n\
echo "["\n\
FIRST=true\n\
for DIR in "$WORKSPACE"/*; do\n\
    if [ -d "$DIR" ]; then\n\
        NAME=$(basename "$DIR")\n\
        MTIME=$(stat -c %%Y "$DIR")\n\
        LANG="unknown"\n\
        FRAMEWORK=""\n\
        GITREPO=""\n\
        GITREMOTE=""\n\
        if [ -f "$DIR/package.json" ]; then\n\
            LANG="node"\n\
            if grep -q "\\"react\\"" "$DIR/package.json" 2>/dev/null; then FRAMEWORK="react"; fi\n\
            if [ -f "$DIR/next.config.js" ]; then FRAMEWORK="next"; fi\n\
        elif [ -f "$DIR/composer.json" ]; then\n\
            LANG="php"\n\
            if [ -f "$DIR/artisan" ]; then FRAMEWORK="laravel"; fi\n\
            if [ -f "$DIR/wp-config.php" ]; then FRAMEWORK="wordpress"; fi\n\
        elif [ -f "$DIR/requirements.txt" ]; then\n\
            LANG="python"\n\
            if [ -f "$DIR/manage.py" ]; then FRAMEWORK="django"; fi\n\
        fi\n\
        if [ -d "$DIR/.git" ]; then\n\
            GITREPO="true"\n\
            GITREMOTE=$(cd "$DIR" && git config --get remote.origin.url 2>/dev/null || echo "")\n\
        fi\n\
        [ "$FIRST" = false ] && echo ","\n\
        FIRST=false\n\
        echo "  {"\n\
        echo "    \\"name\\": \\"$NAME\\","\n\
        echo "    \\"path\\": \\"$DIR\\","\n\
        echo "    \\"language\\": \\"$LANG\\","\n\
        echo "    \\"framework\\": \\"$FRAMEWORK\\","\n\
        echo "    \\"lastModified\\": $MTIME,"\n\
        echo "    \\"isGitRepo\\": \\"$GITREPO\\","\n\
        echo "    \\"gitRemote\\": \\"$GITREMOTE\\""\n\
        echo -n "  }"\n\
    fi\n\
done\n\
echo ""\n\
echo "]"\n' > /usr/local/bin/herodev-projects && chmod +x /usr/local/bin/herodev-projects

# Script de logs de serviço
RUN printf '#!/bin/bash\n\
SERVICE=$1\n\
LINES=${2:-50}\n\
if [ -z "$SERVICE" ]; then\n\
    echo "Usage: herodev-logs <service-name> [lines]"\n\
    exit 1\n\
fi\n\
journalctl -u "$SERVICE" -n "$LINES" --no-pager --output=short-iso\n' \
> /usr/local/bin/herodev-logs && chmod +x /usr/local/bin/herodev-logs

# Script de healthcheck de todos os serviços (retorna JSON)
RUN printf '#!/bin/bash\n\
SERVICES=("apache2" "mariadb" "code-server")\n\
# Adicionar serviços opcionais se instalados\n\
[ -f /usr/local/bin/filebrowser ] && SERVICES+=("filebrowser")\n\
[ -f /usr/bin/redis-server ] && SERVICES+=("redis-server")\n\
[ -f /usr/bin/mongod ] && SERVICES+=("mongod")\n\
[ -f /usr/bin/mongo-express ] && SERVICES+=("mongo-express")\n\
[ -f /usr/sbin/nginx ] && SERVICES+=("nginx")\n\
[ -f /usr/local/bin/prometheus ] && SERVICES+=("prometheus")\n\
[ -f /usr/sbin/grafana-server ] && SERVICES+=("grafana-server")\n\
\n\
echo "{"\n\
echo "  \\"timestamp\\": \\"$(date -Iseconds)\\","\n\
echo "  \\"services\\": {"\n\
FIRST=true\n\
for SERVICE in "${SERVICES[@]}"; do\n\
    [ "$FIRST" = false ] && echo ","\n\
    FIRST=false\n\
    if systemctl is-active --quiet "$SERVICE"; then\n\
        STATUS="healthy"\n\
    else\n\
        STATUS="unhealthy"\n\
    fi\n\
    echo -n "    \\"$SERVICE\\": \\"$STATUS\\""\n\
done\n\
echo ""\n\
echo "  }"\n\
echo "}"\n' > /usr/local/bin/herodev-health && chmod +x /usr/local/bin/herodev-health

# Script de listagem de serviços instalados
RUN printf '#!/bin/bash\n\
echo "{"\n\
echo "  \\"core\\": [\"apache2\", \"mariadb\", \"code-server\", \"phpmyadmin\\"],"\n\
echo "  \\"optional\\": ["\n\
FIRST=true\n\
[ -f /usr/local/bin/filebrowser ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"filebrowser\\""; FIRST=false; }\n\
[ -f /usr/bin/redis-server ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"redis\\""; FIRST=false; }\n\
[ -f /usr/bin/mongod ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"mongodb\\""; FIRST=false; }\n\
[ -f /usr/bin/mongo-express ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"mongo-express\\""; FIRST=false; }\n\
[ -f /usr/sbin/nginx ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"nginx\\""; FIRST=false; }\n\
[ -f /usr/local/bin/prometheus ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"prometheus\\""; FIRST=false; }\n\
[ -f /usr/sbin/grafana-server ] && { [ "$FIRST" = false ] && echo -n ", "; echo -n "\\"grafana\\""; FIRST=false; }\n\
echo ""\n\
echo "  ]"\n\
echo "}"\n' > /usr/local/bin/herodev-services && chmod +x /usr/local/bin/herodev-services

# Script de ajuda
RUN printf '#!/bin/bash\n\
cat << EOF\n\
HeroDev Container Helper Scripts:\n\
\n\
  herodev-status <service>    Get service status (JSON)\n\
  herodev-info                Get container info (JSON)\n\
  herodev-projects [path]     List projects with detection (JSON)\n\
  herodev-logs <service> [n]  Get service logs (last n lines)\n\
  herodev-health              Check all services health (JSON)\n\
  herodev-services            List installed services (JSON)\n\
\n\
Examples:\n\
  herodev-status apache2\n\
  herodev-projects\n\
  herodev-logs mariadb 100\n\
  herodev-services\n\
\n\
Core services:\n\
  - apache2\n\
  - mariadb\n\
  - code-server\n\
  - phpmyadmin (web interface)\n\
EOF\n' > /usr/local/bin/herodev-help && chmod +x /usr/local/bin/herodev-help

# Variáveis de ambiente para identificação
ENV HERODEV_VERSION=1.0.0
ENV HERODEV_TYPE=development
ENV WORKSPACE_PATH=/workspace
ENV WWW_PATH=/workspace/www

# ---------------- VOLUMES ----------------
VOLUME ["/sys/fs/cgroup"]
VOLUME ["/workspace"]
VOLUME ["/home/dev/.config/code-server"]
VOLUME ["/home/dev/.local/share/code-server"]
VOLUME ["/var/lib/mysql"]

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
