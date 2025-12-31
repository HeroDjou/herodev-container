FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------- BASE ----------------
RUN apt update && apt install -y \
    systemd systemd-sysv \
    apache2 \
    php php-cli php-mysql php-curl php-gd php-mbstring php-xml php-zip \
    mariadb-server \
    curl wget unzip git ca-certificates gnupg lsb-release \
    python3 python3-pip python3-venv \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# ---------------- NODE ----------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
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

# ---------------- VOLUMES ----------------
VOLUME ["/sys/fs/cgroup"]
VOLUME ["/workspace"]
VOLUME ["/home/dev/.config/code-server"]
VOLUME ["/home/dev/.local/share/code-server"]
VOLUME ["/var/lib/mysql"]

STOPSIGNAL SIGRTMIN+3
CMD ["/lib/systemd/systemd"]
