#!/bin/bash
# Backup completo do MariaDB
# Uso: ./backup-db.sh [nome-do-arquivo]

set -e

BACKUP_DIR="/workspace/backups/db"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${1:-backup_$DATE.sql}"

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

echo "Iniciando backup do MariaDB..."
echo "Arquivo: $BACKUP_DIR/$BACKUP_FILE"

# Backup de todos os bancos
mysqldump -u root -proot --all-databases --single-transaction --routines --triggers > "$BACKUP_DIR/$BACKUP_FILE"

# Compactar
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "Backup concluído: $BACKUP_DIR/$BACKUP_FILE.gz"
echo "Tamanho: $(du -h "$BACKUP_DIR/$BACKUP_FILE.gz" | cut -f1)"

# Listar últimos 5 backups
echo ""
echo "Últimos backups:"
ls -lht "$BACKUP_DIR" | head -6
