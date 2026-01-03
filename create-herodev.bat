@echo off
setlocal

set BASEDIR=%~dp0
set BASEDIR=%BASEDIR:~0,-1%

echo ==========================================
echo       HERODEV IMAGE BUILD
echo ==========================================
echo.
echo Servicos OPCIONAIS disponiveis:
echo.

REM Perguntar sobre cada serviço opcional
set BUILD_ARGS=

:ASK_FILEBROWSER
set /p INSTALL_FILEBROWSER="Instalar File Browser (gerenciador de arquivos web)? (S/N): "
if /i "%INSTALL_FILEBROWSER%"=="S" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_FILEBROWSER=true
    echo   [x] File Browser
) else if /i "%INSTALL_FILEBROWSER%"=="Y" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_FILEBROWSER=true
    echo   [x] File Browser
) else if /i "%INSTALL_FILEBROWSER%"=="N" (
    echo   [ ] File Browser
) else (
    echo Opcao invalida! Digite S ou N.
    goto ASK_FILEBROWSER
)

:ASK_REDIS
set /p INSTALL_REDIS="Instalar Redis (cache e filas)? (S/N): "
if /i "%INSTALL_REDIS%"=="S" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_REDIS=true
    echo   [x] Redis
) else if /i "%INSTALL_REDIS%"=="Y" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_REDIS=true
    echo   [x] Redis
) else if /i "%INSTALL_REDIS%"=="N" (
    echo   [ ] Redis
) else (
    echo Opcao invalida! Digite S ou N.
    goto ASK_REDIS
)

:ASK_MONGODB
set /p INSTALL_MONGODB="Instalar MongoDB + Mongo Express? (S/N): "
if /i "%INSTALL_MONGODB%"=="S" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_MONGODB=true
    echo   [x] MongoDB + Mongo Express
) else if /i "%INSTALL_MONGODB%"=="Y" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_MONGODB=true
    echo   [x] MongoDB + Mongo Express
) else if /i "%INSTALL_MONGODB%"=="N" (
    echo   [ ] MongoDB
) else (
    echo Opcao invalida! Digite S ou N.
    goto ASK_MONGODB
)

:ASK_NGINX
set /p INSTALL_NGINX="Instalar Nginx (servidor web alternativo)? (S/N): "
if /i "%INSTALL_NGINX%"=="S" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_NGINX=true
    echo   [x] Nginx
) else if /i "%INSTALL_NGINX%"=="Y" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_NGINX=true
    echo   [x] Nginx
) else if /i "%INSTALL_NGINX%"=="N" (
    echo   [ ] Nginx
) else (
    echo Opcao invalida! Digite S ou N.
    goto ASK_NGINX
)

:ASK_MONITORING
set /p INSTALL_MONITORING="Instalar Prometheus + Grafana (monitoramento)? (S/N): "
if /i "%INSTALL_MONITORING%"=="S" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_PROMETHEUS=true --build-arg INSTALL_GRAFANA=true
    echo   [x] Prometheus + Grafana
) else if /i "%INSTALL_MONITORING%"=="Y" (
    set BUILD_ARGS=%BUILD_ARGS% --build-arg INSTALL_PROMETHEUS=true --build-arg INSTALL_GRAFANA=true
    echo   [x] Prometheus + Grafana
) else if /i "%INSTALL_MONITORING%"=="N" (
    echo   [ ] Monitoring
) else (
    echo Opcao invalida! Digite S ou N.
    goto ASK_MONITORING
)

echo.
echo Servicos selecionados confirmados!
echo.

REM --------- PODMAN MACHINE ---------
podman machine inspect >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Inicializando Podman Machine...
    podman machine init
)

podman machine start >nul 2>&1
timeout /t 5 /nobreak >nul

echo Construindo a imagem 'herodev-all' a partir do Containerfile...
echo (Isso pode levar varios minutos dependendo dos servicos selecionados)
echo.

podman build%BUILD_ARGS% -t herodev-all "%BASEDIR%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Imagem criada com sucesso!
    echo.
    call "%BASEDIR%\start-herodev.bat"
) else (
    echo.
    echo Erro ao criar a imagem.
    pause
    exit /b 1
)

echo ==========================================
echo       HERODEV IMAGE BUILD FINALIZADO
echo ==========================================
pause
