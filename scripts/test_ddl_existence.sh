#!/bin/bash
# test_ddl_existence.sh
DDL_FILE="schema/ddl_initialization.sql"

if [ ! -f "$DDL_FILE" ]; then
    echo "Error: $DDL_FILE not found."
    exit 1
fi

TABLES=(
    "TB_PROJETO_EXTENSAO"
    "TB_ATIVIDADE"
    "TB_PARTICIPANTE"
    "TB_INSTRUTOR"
    "TB_PARCEIRO"
    "TB_EMISSAO_CERTIFICADO"
    "TB_REGISTRO_FEEDBACK"
    "RL_INSCRICAO_HISTORICO"
    "RL_ALOCACAO_INSTRUTOR"
    "RL_PATROCINIO_EVENTO"
    "RL_MEMBRO_PROJETO"
)

for TABLE in "${TABLES[@]}"; do
    if ! grep -qi "CREATE TABLE $TABLE" "$DDL_FILE"; then
        echo "Missing CREATE TABLE for $TABLE in DDL script."
        exit 1
    fi
done

echo "DDL initialization verification passed."
exit 0
