@echo off
setlocal

set BASEDIR=%~dp0
set BASEDIR=%BASEDIR:~0,-1%

echo ==========================================
echo       VSDESKTOP SETUP
echo ==========================================
echo.

REM Verificar se container está rodando
podman container exists herodev
IF %ERRORLEVEL% NEQ 0 (
    echo Erro: Container herodev não encontrado!
    echo Execute start-herodev.bat primeiro.
    pause
    exit /b 1
)

podman exec herodev true >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Erro: Container herodev não está rodando!
    echo Execute start-herodev.bat primeiro.
    pause
    exit /b 1
)

REM Verificar se já existe
if exist "%BASEDIR%\volumes\workspace\vsdesktop\out\vsdesktop-win32-x64" (
    echo VSDesktop já existe em volumes\workspace\vsdesktop
    echo.
    set /p REBUILD="Deseja recompilar? (S/N): "
    if /i "%REBUILD%"=="S" goto BUILD
    if /i "%REBUILD%"=="Y" goto BUILD
    echo.
    echo Operação cancelada.
    pause
    exit /b 0
)

REM Clonar repositório
echo Clonando repositório vsdesktop...
echo.
podman exec herodev bash -c "cd /workspace && git clone https://github.com/herodjou/vsdesktop.git"

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Erro ao clonar repositório!
    echo Verifique:
    echo - URL do repositório está correta
    echo - Git está instalado no container
    echo - Conexão com internet está funcionando
    echo.
    pause
    exit /b 1
)

echo.
echo Clone concluído com sucesso!
echo.

:BUILD
echo Instalando dependências NPM...
echo (Isso pode levar alguns minutos...)
echo.
podman exec herodev bash -c "cd /workspace/vsdesktop && npm install"

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Erro ao instalar dependências!
    pause
    exit /b 1
)

echo.
echo Compilando VSDesktop para Windows...
echo (Isso pode levar vários minutos...)
echo.
podman exec herodev bash -c "cd /workspace/vsdesktop && npm run package:win"

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo Erro ao compilar VSDesktop!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo       VSDESKTOP INSTALADO COM SUCESSO!
echo ==========================================
echo.
echo Executável gerado em:
echo %BASEDIR%\volumes\workspace\vsdesktop\out\vsdesktop-win32-x64\vsdesktop.exe
echo.
echo Você pode executar diretamente ou usar start-herodev.bat
echo e escolher a opção de GUI.
echo.

set /p LAUNCH="Deseja executar agora? (S/N): "
if /i "%LAUNCH%"=="S" goto LAUNCH_NOW
if /i "%LAUNCH%"=="Y" goto LAUNCH_NOW

echo.
pause
exit /b 0

:LAUNCH_NOW
echo.
echo Iniciando VSDesktop...
start "" "%BASEDIR%\volumes\workspace\vsdesktop\out\vsdesktop-win32-x64\vsdesktop.exe"
timeout /t 2 /nobreak >nul
exit /b 0
