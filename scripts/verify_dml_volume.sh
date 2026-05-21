#!/bin/bash
# verify_dml_volume.sh
DML_FILE="schema/dml_population.sql"

if [ ! -f "$DML_FILE" ]; then
    echo "Error: $DML_FILE not found."
    exit 1
fi

if ! grep -q "generate_series(1, 5500)" "$DML_FILE"; then
    echo "DML script does not appear to generate at least 5,000 participants."
    exit 1
fi

echo "DML volume verification passed."
exit 0
