@echo off
podman machine stop
podman machine rm -f
podman system connection rm podman-machine-default
podman system connection rm podman-machine-default-root

echo Tudo foi de vasco (removido)

pause