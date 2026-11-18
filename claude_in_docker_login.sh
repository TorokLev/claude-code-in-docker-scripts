#!/bin/bash
# claude.sh

CONTAINER_NAME="claude-code-$USER"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Error: Container '$CONTAINER_NAME' is not running. Run start.sh first."
    exit 1
fi

# Execute claude inside the running container and pass any arguments along
docker exec -it "$CONTAINER_NAME" claude "$@"