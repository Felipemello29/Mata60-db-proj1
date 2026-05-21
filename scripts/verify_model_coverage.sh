#!/bin/bash
# verify_model_coverage.sh
MODEL_FILE="docs/conceptual_model.md"

if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: $MODEL_FILE not found."
    exit 1
fi

REQUIRED_ENTITIES=(
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

MISSING=0
for ENTITY in "${REQUIRED_ENTITIES[@]}"; do
    if ! grep -q "$ENTITY" "$MODEL_FILE"; then
        echo "Missing entity: $ENTITY"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo "$MISSING entities missing from model."
    exit 1
fi

echo "All entities present in model."
exit 0
