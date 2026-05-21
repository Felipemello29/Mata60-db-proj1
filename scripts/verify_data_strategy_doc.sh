#!/bin/bash
# verify_data_strategy_doc.sh
STRATEGY_FILE="docs/data_strategy.md"

if [ ! -f "$STRATEGY_FILE" ]; then
    echo "Error: $STRATEGY_FILE not found."
    exit 1
fi

if ! grep -q "5,000" "$STRATEGY_FILE"; then
    echo "Data strategy does not mention the 5,000 record requirement."
    exit 1
fi

echo "Data strategy document verification passed."
exit 0
