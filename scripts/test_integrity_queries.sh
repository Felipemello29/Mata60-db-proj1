#!/bin/bash
# test_integrity_queries.sh
INTEGRITY_FILE="schema/verify_integrity.sql"

if [ ! -f "$INTEGRITY_FILE" ]; then
    echo "Error: $INTEGRITY_FILE not found."
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
    if ! grep -qi "COUNT(\*) FROM $TABLE" "$INTEGRITY_FILE"; then
        echo "Missing volume check for $TABLE in integrity script."
        exit 1
    fi
done

echo "Integrity queries verification passed."
exit 0
