@echo off

REM Verifica se o container existe
podman container exists herodev
IF %ERRORLEVEL% NEQ 0 (
    EXIT /B 0
)

REM Para serviços dentro do container
podman exec herodev systemctl stop apache2
podman exec herodev systemctl stop mariadb

REM Para o container
podman stop herodev

REM Opcional: desligar a machine do Podman
podman machine stop >nul 2>&1
