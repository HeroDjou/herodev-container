@echo off
setlocal

set BASEDIR=%~dp0
set BASEDIR=%BASEDIR:~0,-1%

REM --------- ESTRUTURA ---------
if not exist "%BASEDIR%\volumes" mkdir "%BASEDIR%\volumes"
if not exist "%BASEDIR%\volumes\workspace" mkdir "%BASEDIR%\volumes\workspace"
if not exist "%BASEDIR%\volumes\workspace\www" mkdir "%BASEDIR%\volumes\workspace\www"
if not exist "%BASEDIR%\volumes\db" mkdir "%BASEDIR%\volumes\db"
if not exist "%BASEDIR%\volumes\vscode\config" mkdir "%BASEDIR%\volumes\vscode\config"
if not exist "%BASEDIR%\volumes\vscode\data" mkdir "%BASEDIR%\volumes\vscode\data"

REM --------- PODMAN ---------
podman machine start >nul 2>&1
timeout /t 5 /nobreak >nul

podman container exists herodev
IF %ERRORLEVEL% EQU 0 (
    podman start herodev
) ELSE (
    podman run -d ^
      --name herodev ^
      --privileged ^
      --systemd=always ^
      -p 8080:80 ^
      -p 12777:12777 ^
      -p 8081:8081 ^
      -p 6379:6379 ^
      -p 27017:27017 ^
      -p 8082:8082 ^
      -p 8083:8083 ^
      -p 9090:9090 ^
      -p 3000:3000 ^
      -v "%BASEDIR%\volumes\workspace:/workspace" ^
      -v "%BASEDIR%\volumes\db:/var/lib/mysql" ^
      -v "%BASEDIR%\volumes\vscode\config:/home/dev/.config/code-server" ^
      -v "%BASEDIR%\volumes\vscode\data:/home/dev/.local/share/code-server" ^
      herodev-all
)

podman exec herodev systemctl daemon-reload

REM Habilitar e iniciar serviços core
podman exec herodev systemctl enable apache2 mariadb code-server
podman exec herodev systemctl start apache2 mariadb code-server

REM Detectar e iniciar serviços opcionais se instalados
podman exec herodev bash -c "[ -f /usr/local/bin/filebrowser ] && systemctl enable filebrowser && systemctl start filebrowser || true"
podman exec herodev bash -c "[ -f /usr/bin/redis-server ] && systemctl enable redis-server && systemctl start redis-server || true"
podman exec herodev bash -c "[ -f /usr/bin/mongod ] && systemctl enable mongod && systemctl start mongod || true"
podman exec herodev bash -c "[ -f /usr/bin/mongo-express ] && systemctl enable mongo-express && systemctl start mongo-express || true"
podman exec herodev bash -c "[ -f /usr/sbin/nginx ] && systemctl enable nginx php8.1-fpm && systemctl start nginx php8.1-fpm || true"
podman exec herodev bash -c "[ -f /usr/local/bin/prometheus ] && systemctl enable prometheus && systemctl start prometheus || true"
podman exec herodev bash -c "[ -f /usr/sbin/grafana-server ] && systemctl enable grafana-server && systemctl start grafana-server || true"

echo.
echo ==========================================
echo HERODEV ONLINE
echo ==========================================
echo.
echo SERVIÇOS CORE:
echo   Web:        http://localhost:8080
echo   phpMyAdmin: http://localhost:8080/phpmyadmin
echo   VS Code:    http://localhost:12777

REM Detectar e listar serviços opcionais
podman exec herodev bash -c "[ -f /usr/local/bin/filebrowser ] && echo '  File Browser: http://localhost:8081' || true"
podman exec herodev bash -c "[ -f /usr/bin/mongo-express ] && echo '  Mongo Express: http://localhost:8082' || true"
podman exec herodev bash -c "[ -f /usr/sbin/nginx ] && echo '  Nginx: http://localhost:8083' || true"
podman exec herodev bash -c "[ -f /usr/local/bin/prometheus ] && echo '  Prometheus: http://localhost:9090' || true"
podman exec herodev bash -c "[ -f /usr/sbin/grafana-server ] && echo '  Grafana: http://localhost:3000' || true"

echo ==========================================
echo.

REM --------- GUI VSDESKTOP e outras ---------
:GUI_PROMPT
echo ==========================================
echo INTERFACE GRÁFICA
echo ==========================================
set /p RUN_GUI="Deseja executar a GUI? (S/N): "

REM Verifica S ou Y para SIM
if /i "%RUN_GUI%"=="S" goto CHECK_GUI
if /i "%RUN_GUI%"=="Y" goto CHECK_GUI

REM Verifica N para NÃO
if /i "%RUN_GUI%"=="N" goto TERMINAL_ONLY

REM Entrada inválida
echo.
echo Opção inválida! Digite S ou N.
timeout /t 2 /nobreak >nul
goto GUI_PROMPT

REM --------- TERMINAL APENAS ---------
:TERMINAL_ONLY
echo.
echo Iniciando terminal do container...
timeout /t 2 /nobreak >nul
start cmd /k podman exec -it herodev bash
goto END

REM --------- VERIFICAR/BUILD GUI ---------
:CHECK_GUI
echo Verificando VSDesktop...

set GUI_PATH=%BASEDIR%\volumes\workspace\vsdesktop\out\vsdesktop-win32-x64
set GUI_EXE=%GUI_PATH%\vsdesktop.exe

if exist "%GUI_EXE%" (
    echo.
    echo Iniciando VSDesktop...
    timeout /t 2 /nobreak >nul
    start "" "%GUI_EXE%"
    goto END
) else (
    echo VSDesktop não encontrado!
    echo.
    echo Será necessário compilar na primeira execução.
    echo Isso pode levar alguns minutos...
    echo.
    pause

    REM Verificar se a pasta vsdesktop existe
    if not exist "%BASEDIR%\volumes\workspace\vsdesktop" (
        echo.
        echo Pasta vsdesktop não encontrada em:
        echo %BASEDIR%\volumes\workspace\vsdesktop
        echo.
        :ASK_SETUP
        set /p RUN_SETUP="Deseja executar o setup do VSDesktop agora? (S/N): "
        
        if /i "%RUN_SETUP%"=="S" goto RUN_SETUP
        if /i "%RUN_SETUP%"=="Y" goto RUN_SETUP
        if /i "%RUN_SETUP%"=="N" goto CANCEL_SETUP
        
        echo.
        echo Opção inválida! Digite S ou N.
        timeout /t 2 /nobreak >nul
        goto ASK_SETUP
        
        :RUN_SETUP
        echo.
        echo Executando setup do VSDesktop...
        call "%BASEDIR%\win_setup-vsdesktop.bat"
        goto END
        
        :CANCEL_SETUP
        echo.
        echo Operação cancelada.
        pause
        goto END
    )

    echo.
    echo Iniciando compilação do VSDesktop...
    echo Abrindo terminal do container para build...
    echo.
    echo Comando a executar:
    echo   cd /workspace/vsdesktop
    echo   npm run package:win
    echo.
    timeout /t 3 /nobreak >nul

    REM Abre terminal interativo para executar o build
    start cmd /k podman exec -it herodev bash -c "cd /workspace/vsdesktop && npm run package:win"

    echo.
    echo Build em progresso! Acompanhe no terminal do container.
    echo.
    echo Aguardando conclusão da compilação...
    echo.

    REM Loop de verificação do executável
    :BUILD_LOOP
    timeout /t 5 /nobreak >nul
    
    if exist "%GUI_EXE%" (
        echo Iniciando VSDesktop...
        timeout /t 2 /nobreak >nul
        start "" "%GUI_EXE%"
        goto END
    ) else (
        echo Verificando...
        goto BUILD_LOOP
    )
)


:END
echo.
REM Abre terminal interativo no container
REM start cmd /k podman exec -it herodev bash
pause
endlocal