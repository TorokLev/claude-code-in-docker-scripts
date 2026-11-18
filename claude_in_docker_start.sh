#!/bin/bash
# start.sh

# Exit immediately if a command fails
set -e

CONTAINER_NAME="claude-code-$USER"
IMAGE_NAME="claude-code-sandbox"
WORKSPACE_DIR="$HOME/claude-workspace"
CONFIG_DIR="$HOME/.claude"

# Check if already running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container '$CONTAINER_NAME' is already running."
    exit 0
fi

# Remove dead container if it exists
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1

echo "Starting container '$CONTAINER_NAME' in the background..."
docker run -d \
    --name "$CONTAINER_NAME" \
    -e HOME=/tmp/home \
    -v "$CONFIG_DIR":/tmp/home/.claude \
    -v "$HOME/.gitconfig":/tmp/home/.gitconfig:ro \
    -v "$WORKSPACE_DIR":/workspace \
    "$IMAGE_NAME"

echo "Container started. You can now use the access scripts."
