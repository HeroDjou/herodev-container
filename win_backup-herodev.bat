@echo off
setlocal enabledelayedexpansion

set BASEDIR=%~dp0
set BASEDIR=%BASEDIR:~0,-1%
set CONFIG_FILE=%BASEDIR%\.backup-config

echo ==========================================
echo       HERODEV BACKUP
echo ==========================================
echo.

REM --------- VERIFICAR CONTAINER ---------
podman container exists herodev >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    podman ps --filter "name=herodev" --format "{{.Status}}" | findstr /C:"Up" >nul 2>&1
    IF %ERRORLEVEL% EQU 0 (
        echo [AVISO] Container herodev está rodando!
        echo.
        echo Para evitar erros com arquivos em uso, recomenda-se parar o container.
        echo.
        set /p STOP_CONTAINER="Deseja parar o container agora? (S/N): "
        
        if /i "!STOP_CONTAINER!"=="S" (
            echo.
            echo Parando container...
            podman stop herodev >nul 2>&1
            timeout /t 3 /nobreak >nul
            echo Container parado!
            echo.
        ) else if /i "!STOP_CONTAINER!"=="Y" (
            echo.
            echo Parando container...
            podman stop herodev >nul 2>&1
            timeout /t 3 /nobreak >nul
            echo Container parado!
            echo.
        ) else (
            echo.
            echo [AVISO] Backup continuará com container rodando.
            echo Alguns arquivos podem não ser incluídos.
            echo.
            timeout /t 3 /nobreak >nul
        )
    )
)

REM --------- TIPO DE BACKUP ---------
:ASK_BACKUP_TYPE
echo Tipo de backup:
echo   [1] Ambiente completo (tudo)
echo   [2] Apenas volumes
echo.
set /p BACKUP_TYPE="Escolha uma opção (1 ou 2): "

if "%BACKUP_TYPE%"=="1" (
    set BACKUP_MODE=full
    echo.
    echo [x] Backup completo selecionado
) else if "%BACKUP_TYPE%"=="2" (
    set BACKUP_MODE=volumes
    echo.
    echo [x] Backup de volumes selecionado
) else (
    echo.
    echo Opção inválida! Digite 1 ou 2.
    timeout /t 2 /nobreak >nul
    echo.
    goto ASK_BACKUP_TYPE
)

echo.

REM --------- DESTINO DO BACKUP ---------
set LAST_DEST=
if exist "%CONFIG_FILE%" (
    set /p LAST_DEST=<"%CONFIG_FILE%"
)

if not "!LAST_DEST!"=="" (
    echo Último destino usado: !LAST_DEST!
    echo.
    set /p USE_LAST="Usar este destino? (S/N): "
    
    if /i "!USE_LAST!"=="S" (
        set DEST_FOLDER=!LAST_DEST!
    ) else if /i "!USE_LAST!"=="Y" (
        set DEST_FOLDER=!LAST_DEST!
    ) else (
        set /p DEST_FOLDER="Digite o caminho da pasta de destino: "
    )
) else (
    set /p DEST_FOLDER="Digite o caminho da pasta de destino: "
)

REM Remover barra final se existir
if "!DEST_FOLDER:~-1!"=="\" set DEST_FOLDER=!DEST_FOLDER:~0,-1!

REM Validar se pasta existe
if not exist "!DEST_FOLDER!" (
    echo.
    echo Pasta não encontrada: !DEST_FOLDER!
    echo.
    set /p CREATE_FOLDER="Deseja criar a pasta? (S/N): "
    
    if /i "!CREATE_FOLDER!"=="S" (
        mkdir "!DEST_FOLDER!" 2>nul
        if errorlevel 1 (
            echo.
            echo Erro ao criar pasta!
            pause
            exit /b 1
        )
    ) else if /i "!CREATE_FOLDER!"=="Y" (
        mkdir "!DEST_FOLDER!" 2>nul
        if errorlevel 1 (
            echo.
            echo Erro ao criar pasta!
            pause
            exit /b 1
        )
    ) else (
        echo.
        echo Operação cancelada.
        pause
        exit /b 0
    )
)

REM Remover aspas do caminho se existir
set DEST_FOLDER=!DEST_FOLDER:"=!

REM Salvar destino para próxima vez
echo !DEST_FOLDER!>"%CONFIG_FILE%"

REM --------- NOME DO ARQUIVO ---------
set ZIP_NAME=backup-herodev.zip
set ZIP_PATH=!DEST_FOLDER!\!ZIP_NAME!

echo.
echo ==========================================
echo Criando backup...
echo (Isso pode levar alguns minutos dependendo do tamanho)
echo.

REM --------- EXECUTAR BACKUP ---------
if "!BACKUP_MODE!"=="full" (
    REM Backup completo - comprimir tudo sem pasta raiz
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$destZip = '!ZIP_PATH!'; " ^
        "if (Test-Path $destZip) { Remove-Item $destZip -Force }; " ^
        "$items = Get-ChildItem -Path '%BASEDIR%' -Exclude '.git','.backup-config' | Select-Object -ExpandProperty FullName; " ^
        "$count = (Get-ChildItem -Path '%BASEDIR%' -Recurse -File -Exclude '*.git*' | Where-Object { $_.FullName -notmatch 'coder-logs' }).Count; " ^
        "Write-Host \"Comprimindo $count arquivos...\"; " ^
        "Compress-Archive -Path $items -DestinationPath $destZip -CompressionLevel Optimal -Force; " ^
        "Write-Host \"Concluído!\""
    
    if errorlevel 1 (
        echo.
        echo [ERRO] Falha ao criar backup completo!
        pause
        exit /b 1
    )
) else (
    REM Backup de volumes - comprimir pasta volumes mantendo estrutura
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$destZip = '!ZIP_PATH!'; " ^
        "if (Test-Path $destZip) { Remove-Item $destZip -Force }; " ^
        "$count = (Get-ChildItem -Path '%BASEDIR%\\volumes' -Recurse -File | Where-Object { $_.FullName -notmatch 'coder-logs' }).Count; " ^
        "Write-Host \"Comprimindo $count arquivos...\"; " ^
        "Compress-Archive -Path '%BASEDIR%\\volumes' -DestinationPath $destZip -CompressionLevel Optimal -Force; " ^
        "Write-Host \"Concluído!\""
    
    if errorlevel 1 (
        echo.
        echo [ERRO] Falha ao criar backup de volumes!
        pause
        exit /b 1
    )
)

echo.
echo ==========================================
echo       BACKUP CONCLUÍDO COM SUCESSO!
echo ==========================================
echo.
echo Arquivo: !ZIP_NAME!
echo Local: !DEST_FOLDER!

REM Mostrar tamanho do arquivo
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$size = (Get-Item '!ZIP_PATH!').Length; " ^
    "$sizeMB = [math]::Round($size / 1MB, 2); " ^
    "Write-Host \"Tamanho: $sizeMB MB\""
echo.

pause
endlocal
