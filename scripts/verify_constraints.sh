#!/bin/bash
# verify_constraints.sh
DDL_FILE="schema/ddl_initialization.sql"

if [ ! -f "$DDL_FILE" ]; then
    echo "Error: $DDL_FILE not found."
    exit 1
fi

# Check for specific constraints
CONSTRAINTS=(
    "CHECK (VL_NOTA_SATISFACAO BETWEEN 1 AND 5)"
    "CHECK (VL_NOTA_AVALIACAO BETWEEN 0 AND 10)"
    "DEFAULT CURRENT_DATE"
    "CHECK (ST_PRESENCA IN ('PRESENTE', 'AUSENTE'))"
)

for CONSTRAINT in "${CONSTRAINTS[@]}"; do
    if ! grep -qi "$CONSTRAINT" "$DDL_FILE"; then
        echo "Missing constraint: $CONSTRAINT"
        exit 1
    fi
done

echo "Business rules and constraints verification passed."
exit 0
