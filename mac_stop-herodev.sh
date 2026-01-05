#!/bin/bash

# Verifica se o container existe
if ! podman container exists herodev; then
    exit 0
fi

# Para serviços dentro do container
podman exec herodev systemctl stop apache2
podman exec herodev systemctl stop mariadb

echo "Serviços dentro do container parados."

# Para o container
podman stop herodev

# Opcional: desligar a machine do Podman
podman machine stop &>/dev/null
