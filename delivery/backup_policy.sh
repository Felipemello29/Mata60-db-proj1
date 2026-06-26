#!/bin/bash
# Script de Backup Diário do Banco de Dados
# Requisito do Marco 2 (Políticas de Backup)
# Deve ser configurado via CRON no servidor PostgreSQL. Exemplo:
# 0 2 * * * /caminho/para/backup_policy.sh

DB_NAME="mata60_extension"
DB_USER="postgres"
BACKUP_DIR="/var/backups/postgresql/mata60"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_${DATE}.sql"
LOG_FILE="/var/log/pg_backup.log"

# Verifica se o diretório de backup existe, senão cria
mkdir -p "$BACKUP_DIR"

# Executa o backup lógico completo no formato customizado (c)
echo "[$(date)] Iniciando backup do banco $DB_NAME..." >> "$LOG_FILE"

pg_dump -U "$DB_USER" -F c -f "$BACKUP_FILE" "$DB_NAME" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup concluído com sucesso: $BACKUP_FILE" >> "$LOG_FILE"
    
    # Política de retenção: Remove backups com mais de 7 dias
    find "$BACKUP_DIR" -type f -name "*.sql" -mtime +7 -exec rm {} \;
    echo "[$(date)] Backups antigos (>7 dias) removidos de acordo com a política." >> "$LOG_FILE"
else
    echo "[$(date)] ERRO: Falha ao realizar o backup do banco $DB_NAME." >> "$LOG_FILE"
    # Aqui pode-se adicionar um curl ou mail para alertar o administrador
fi
