#!/bin/bash
# shell.sh

CONTAINER_NAME="claude-code-$USER"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running. Run start.sh first."
    exit 1
fi

echo "Logging into $CONTAINER_NAME as user $(id -un)..."
docker exec -it "$CONTAINER_NAME" /bin/bash