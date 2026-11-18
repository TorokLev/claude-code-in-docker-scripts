#!/bin/bash
# stop.sh

CONTAINER_NAME="claude-code-$USER"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping and removing container '$CONTAINER_NAME'..."
    docker rm -f "$CONTAINER_NAME"
    echo "Container stopped."
else
    echo "Container '$CONTAINER_NAME' is not running."
fi