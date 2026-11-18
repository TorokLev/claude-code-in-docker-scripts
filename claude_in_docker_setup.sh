#!/bin/bash
# claude_in_docker_setup.sh

# Exit immediately if any command fails
set -e

CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)

echo "0. Checking rootless Docker prerequisites..."
# Check if the user already has a subuid and subgid allocation
if ! grep -q "^${CURRENT_USER}:" /etc/subuid || ! grep -q "^${CURRENT_USER}:" /etc/subgid; then
    echo "   Missing subuid/subgid entries for user: $CURRENT_USER"
    echo "   Requesting sudo access to configure user namespace mappings..."
    
    # Calculate a unique starting ID based on the user's UID to prevent collisions 
    # on multi-user systems. (e.g., UID 1000 gets 165536000)
   # Use modulo to handle massive LDAP/AD UIDs safely without 32-bit overflow
    SAFE_UID=$(( CURRENT_UID % 10000 ))
    START_ID=$(( 1000000 + SAFE_UID * 65536 )) 

    sudo sh -c "echo '${CURRENT_USER}:${START_ID}:65536' >> /etc/subuid"
    sudo sh -c "echo '${CURRENT_USER}:${START_ID}:65536' >> /etc/subgid"
    echo "   Successfully added subuid and subgid entries."
else
    echo "   Subuid/subgid entries found."
fi

echo "1. Checking if rootless Docker is installed..."
# If the systemd service doesn't exist, run the rootless installer
if ! systemctl --user status docker >/dev/null 2>&1; then
    echo "   Rootless Docker service not found. Installing..."
    dockerd-rootless-setuptool.sh install
    
    echo "   Enabling lingering so Docker stays running after logout..."
    loginctl enable-linger "$CURRENT_USER"
    
    echo "   Starting the rootless Docker daemon..."
    systemctl --user daemon-reload
    systemctl --user enable --now docker
    sleep 2
else
    echo "   Rootless Docker service is already installed and running."
fi

echo "2. Checking Docker daemon connection..."
# Export the rootless socket for this script session
export DOCKER_HOST="unix:///run/user/${CURRENT_UID}/docker.sock"

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Cannot connect to Docker daemon even after setup."
    exit 1
fi

# Make the rootless socket persistent for future terminal sessions
if ! grep -q "DOCKER_HOST=unix:///run/user" ~/.bashrc; then
    echo "   Adding DOCKER_HOST to ~/.bashrc for future sessions..."
    echo '' >> ~/.bashrc
    echo '# Rootless Docker socket' >> ~/.bashrc
    echo 'export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"' >> ~/.bashrc
    echo "   IMPORTANT: You must run 'source ~/.bashrc' after this script finishes!"
fi
echo "   Success! Connected to rootless Docker."

IMAGE_NAME="claude-code-sandbox"
WORKSPACE_DIR="$HOME/claude-workspace"
CONFIG_DIR="$HOME/.claude"

echo "3. Checking Claude directories..."
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$CONFIG_DIR"
touch "$HOME/.gitconfig"

# Check if the image exists (temporarily disable 'set -e' for the check)
set +e
docker image inspect "$IMAGE_NAME" >/dev/null 2>&1
IMAGE_EXISTS=$?
set -e

if [ $IMAGE_EXISTS -ne 0 ]; then
    echo "4. Image '$IMAGE_NAME' not found. Building it now..."
    
    BUILD_DIR=$(mktemp -d)
    cat << 'EOF' > "$BUILD_DIR/Dockerfile"
FROM node:22-slim

# We keep node and python in case your own projects need them, 
# but Claude no longer depends on them to install.
RUN apt-get update && apt-get install -y git curl jq python3 python3-pip python3-venv && rm -rf /var/lib/apt/lists/*

# Run the native installer and move it to a global path
RUN curl -fsSL https://claude.ai/install.sh | bash && \
mv /root/.local/bin/claude /usr/local/bin/claude

WORKDIR /workspace
CMD ["tail", "-f", "/dev/null"]
EOF

    # Standard build (network=host is no longer strictly necessary, but safe to keep)
    docker build --network=host -t "$IMAGE_NAME" "$BUILD_DIR"
    rm -rf "$BUILD_DIR"
    
    echo "   Image built successfully."
else
    echo "4. Image '$IMAGE_NAME' already exists. Skipping build."
fi

echo "--------------------------------------------------------"
echo "Setup complete! Your workspace is mapped to: $WORKSPACE_DIR"
echo "Please run: source ~/.bashrc"
echo "Then start your environment with: ./claude_in_docker_start.sh"
