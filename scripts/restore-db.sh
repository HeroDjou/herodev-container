#!/bin/bash
# Restore de backup do MariaDB
# Uso: ./restore-db.sh <arquivo-backup.sql.gz>

set -e

if [ -z "$1" ]; then
    echo "Uso: ./restore-db.sh <arquivo-backup.sql.gz>"
    echo ""
    echo "Backups disponíveis:"
    ls -lh /workspace/backups/db/*.gz 2>/dev/null || echo "Nenhum backup encontrado"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Erro: Arquivo $BACKUP_FILE não encontrado!"
    exit 1
fi

echo "ATENÇÃO: Este processo irá sobrescrever todos os bancos de dados!"
echo "Backup: $BACKUP_FILE"
echo ""
read -p "Confirma o restore? (digite 'SIM' para confirmar): " CONFIRM

if [ "$CONFIRM" != "SIM" ]; then
    echo "Restore cancelado."
    exit 0
fi

echo "Descompactando backup..."
gunzip -c "$BACKUP_FILE" > /tmp/restore.sql

echo "Restaurando banco de dados..."
mysql -u root -proot < /tmp/restore.sql

echo "Limpando arquivo temporário..."
rm /tmp/restore.sql

echo ""
echo "Restore concluído com sucesso!"
echo "Reinicie os serviços que utilizam o banco se necessário."
