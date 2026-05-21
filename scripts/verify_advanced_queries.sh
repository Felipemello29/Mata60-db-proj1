#!/bin/bash
# verify_advanced_queries.sh
QUERY_FILE="schema/advanced_queries.sql"

if [ ! -f "$QUERY_FILE" ]; then
    echo "Error: $QUERY_FILE not found."
    exit 1
fi

# Count the number of SELECT statements
QUERY_COUNT=$(grep -ci "SELECT" "$QUERY_FILE")

if [ $QUERY_COUNT -lt 20 ]; then
    echo "Found only $QUERY_COUNT queries, expected at least 20."
    exit 1
fi

echo "Advanced queries verification passed."
exit 0
