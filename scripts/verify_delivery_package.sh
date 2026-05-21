#!/bin/bash
# verify_delivery_package.sh
PACKAGE_DIR="delivery"
FILES=(
    "final_script.sql"
    "technical_report.md"
)

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "Error: $PACKAGE_DIR directory not found."
    exit 1
fi

for FILE in "${FILES[@]}"; do
    if [ ! -f "$PACKAGE_DIR/$FILE" ]; then
        echo "Missing file in delivery package: $FILE"
        exit 1
    fi
done

echo "Delivery package verification passed."
exit 0
