#!/bin/bash
# verify_intermediate_queries.sh
QUERY_FILE="schema/intermediate_queries.sql"

if [ ! -f "$QUERY_FILE" ]; then
    echo "Error: $QUERY_FILE not found."
    exit 1
fi

# Count the number of SELECT statements
QUERY_COUNT=$(grep -ci "SELECT" "$QUERY_FILE")

if [ $QUERY_COUNT -lt 10 ]; then
    echo "Found only $QUERY_COUNT queries, expected at least 10."
    exit 1
fi

echo "Intermediate queries verification passed."
exit 0
