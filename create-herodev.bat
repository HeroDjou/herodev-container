@echo off
setlocal

set BASEDIR=%~dp0
set BASEDIR=%BASEDIR:~0,-1%

REM --------- PODMAN MACHINE ---------
podman machine inspect >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    podman machine init
)

podman machine start >nul 2>&1
timeout /t 5 /nobreak >nul

echo ==========================================
echo       HERODEV IMAGE BUILD
echo ==========================================
echo.

echo Construindo a imagem 'herodev-all' a partir do Containerfile...
podman build -t herodev-all "%BASEDIR%"

if %ERRORLEVEL% EQU 0 (
    echo Imagem criada com sucesso!
    call "%BASEDIR%\start-herodev.bat"
) else (
    echo Erro ao criar a imagem.
    pause
    exit /b 1
)

echo ==========================================
echo       HERODEV IMAGE BUILD FINALIZADO
echo ==========================================
pause
