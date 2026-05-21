#!/bin/bash
# verify_logical_model.sh
LOGICAL_FILE="docs/logical_model.md"

if [ ! -f "$LOGICAL_FILE" ]; then
    echo "Error: $LOGICAL_FILE not found."
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
    if ! grep -q "$TABLE" "$LOGICAL_FILE"; then
        echo "Missing table in logical model: $TABLE"
        exit 1
    fi
done

# Check for Primary Keys
if ! grep -q "PK" "$LOGICAL_FILE"; then
    echo "Primary Keys not defined in logical model."
    exit 1
fi

# Check for Foreign Keys
if ! grep -q "FK" "$LOGICAL_FILE"; then
    echo "Foreign Keys not defined in logical model."
    exit 1
fi

echo "Logical model verification passed."
exit 0
