@echo off
REM ========================================================================
REM IC Extension Management Database - FULL Backup Routine
REM Compliant with PBR1 (Política de Backup e Recuperação FULL)
REM ========================================================================
REM Estratégias de Backup:
REM Tipo: Full (completo).
REM Artefatos: Bancos de dados, catálogo e configurações.
REM Temporalidade: Semanal.
REM Operador: dbbackup_ic
REM ========================================================================

set DB_NAME=banco_extensao_ic
set DB_USER=dbbackup_ic
set BACKUP_DIR=C:\backups\db_ic
set TIMESTAMP=%date:~6,4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set BACKUP_FILE=%BACKUP_DIR%\%DB_NAME%_FULL_%TIMESTAMP%.sql

echo [INFO] Iniciando rotina de Backup FULL (PBR1)...
echo [INFO] Destino local: %BACKUP_FILE%

REM Cria o diretorio se nao existir
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Executa o pg_dump (requer senha ou pgpass configurado)
pg_dump -U %DB_USER% -h localhost -p 5432 -F c -b -v -f "%BACKUP_FILE%" %DB_NAME%

if %ERRORLEVEL% equ 0 (
    echo [SUCESSO] Backup FULL concluido com sucesso.
    echo [INFO] Registrando log de sucesso.
    echo %date% %time% - SUCCESS - %BACKUP_FILE% >> "%BACKUP_DIR%\backup_log.txt"
) else (
    echo [ERRO] Falha durante o processo de backup!
    echo [INFO] Registrando log de erro.
    echo %date% %time% - ERROR - Falha ao gerar %BACKUP_FILE% >> "%BACKUP_DIR%\backup_log.txt"
)

REM Simulação de upload para armazenamento online criptografado
echo [INFO] Iniciando rotina de sincronizacao remota (Drive/Dropbox)...
REM call aws s3 cp "%BACKUP_FILE%" s3://meubucket-backups/ic-extensao/
echo [SUCESSO] Rotina finalizada.
