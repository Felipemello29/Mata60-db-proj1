#!/bin/bash
# verify_performance_plan.sh
INDEX_FILE="schema/indexing_plan.sql"

if [ ! -f "$INDEX_FILE" ]; then
    echo "Error: $INDEX_FILE not found."
    exit 1
fi

if ! grep -qi "CREATE INDEX" "$INDEX_FILE"; then
    echo "Indexing plan does not contain CREATE INDEX statements."
    exit 1
fi

echo "Performance plan verification passed."
exit 0
