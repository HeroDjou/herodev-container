#!/bin/bash

# mac_backup-herodev.sh
# Backup simples do projeto HeroDev (macOS)

BASEDIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$BASEDIR/.backup-config"

echo "=========================================="
echo "       HERODEV BACKUP"
echo "=========================================="
echo ""

# --------- VERIFICAR CONTAINER ---------
if podman container exists herodev >/dev/null 2>&1; then
    if podman ps --filter "name=herodev" --format "{{.Status}}" | grep -q "Up"; then
        echo "[AVISO] Container herodev está rodando!"
        echo "Para evitar erros com arquivos em uso, recomenda-se parar o container."
        read -r -p "Deseja parar o container agora? (S/N): " STOP_CONTAINER
        case "$STOP_CONTAINER" in
            s|S|y|Y)
                echo "Parando container..."
                podman stop herodev >/dev/null 2>&1 || true
                sleep 2
                echo "Container parado!"
                ;;
            *)
                echo "Continuando com container rodando (alguns arquivos podem não ser incluídos)."
                ;;
        esac
    fi
fi

# --------- TIPO DE BACKUP ---------
while true; do
    echo "Tipo de backup:"
    echo "  [1] Ambiente completo (tudo)"
    echo "  [2] Apenas volumes"
    echo ""
    read -r -p "Escolha uma opção (1 ou 2): " BACKUP_TYPE
    case "$BACKUP_TYPE" in
        1)
            BACKUP_MODE="full"
            echo "[x] Backup completo selecionado"
            break
            ;;
        2)
            BACKUP_MODE="volumes"
            echo "[x] Backup de volumes selecionado"
            break
            ;;
        *)
            echo "Opção inválida! Digite 1 ou 2."
            ;;
    esac
done

echo ""

# --------- DESTINO DO BACKUP ---------
LAST_DEST=""
if [ -f "$CONFIG_FILE" ]; then
    LAST_DEST=$(cat "$CONFIG_FILE")
fi

if [ -n "$LAST_DEST" ]; then
    echo "Último destino usado: $LAST_DEST"
    read -r -p "Usar este destino? (S/N): " USE_LAST
    case "$USE_LAST" in
        s|S|y|Y)
            DEST_FOLDER="$LAST_DEST"
            ;;
        *)
            read -r -p "Digite o caminho da pasta de destino: " DEST_FOLDER
            ;;
    esac
else
    read -r -p "Digite o caminho da pasta de destino: " DEST_FOLDER
fi

# Expandir ~ para home directory
DEST_FOLDER="${DEST_FOLDER/#\~/$HOME}"
# Remover barra final se existir
DEST_FOLDER="${DEST_FOLDER%/}"

if [ -z "$DEST_FOLDER" ]; then
    echo "Destino vazio. Abortando."
    exit 1
fi

if [ ! -d "$DEST_FOLDER" ]; then
    echo "Pasta não encontrada: $DEST_FOLDER"
    read -r -p "Criar pasta? (S/N): " CREATE_DIR
    case "$CREATE_DIR" in
        s|S|y|Y)
            mkdir -p "$DEST_FOLDER" || { echo "Falha ao criar pasta"; exit 1; }
            ;;
        *)
            echo "Operação cancelada."; exit 1
            ;;
    esac
fi

# Salvar destino para próxima vez
echo "$DEST_FOLDER" > "$CONFIG_FILE"

# --------- NOME DO ARQUIVO ---------
ZIP_NAME="backup-herodev.zip"
ZIP_PATH="$DEST_FOLDER/$ZIP_NAME"

echo ""
echo "=========================================="
echo "Tipo: $BACKUP_MODE"
echo "Destino: $ZIP_PATH"
echo ""
read -r -p "Confirmar backup? (S/N): " CONFIRM
case "$CONFIRM" in
    s|S|y|Y) ;;
    *) echo "Operação cancelada."; exit 0 ;;
esac

echo ""
echo "Criando backup... (pode levar alguns minutos)"
echo ""

# Remover arquivo anterior se existir
[ -f "$ZIP_PATH" ] && rm -f "$ZIP_PATH"

if [ "$BACKUP_MODE" = "full" ]; then
    # Backup completo - comprimir todo o diretório do projeto, excluindo .git, node_modules, coder-logs e o arquivo de config
    (cd "$BASEDIR" && \
        zip -r "$ZIP_PATH" . -x "*/.git/*" "*.backup-config" "*/coder-logs/*" "*/node_modules/*" -q) || {
        echo ""
        echo "[ERRO] Falha ao criar backup completo!"
        read -r -p "Pressione ENTER para continuar..."
        exit 1
    }
else
    # Backup de volumes - comprimir apenas a pasta volumes
    if [ ! -d "$BASEDIR/volumes" ]; then
        echo ""
        echo "[ERRO] Pasta volumes não encontrada!"
        read -r -p "Pressione ENTER para continuar..."
        exit 1
    fi
    (cd "$BASEDIR" && \
        zip -r "$ZIP_PATH" "volumes" -x "volumes/**/.git/*" "volumes/**/coder-logs/*" "volumes/**/node_modules/*" "*.backup-config" -q) || {
        echo ""
        echo "[ERRO] Falha ao criar backup de volumes!"
        read -r -p "Pressione ENTER para continuar..."
        exit 1
    }
fi

echo ""
echo "Backup criado: $ZIP_PATH"

# Mostrar tamanho do arquivo
    if [ -f "$ZIP_PATH" ]; then
    SIZE=$(stat -f%z "$ZIP_PATH" 2>/dev/null || stat -c%s "$ZIP_PATH" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 0 ] 2>/dev/null; then
        SIZE_MB=$((SIZE / 1024 / 1024))
        echo "Tamanho: ${SIZE_MB} MB"
    fi
fi

echo ""
read -r -p "Pressione ENTER para continuar..."
