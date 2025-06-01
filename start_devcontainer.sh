#!/usr/bin/env bash
set -e

# Verify devcontainer CLI is installed
if ! command -v devcontainer &>/dev/null; then
  echo "❌ devcontainer CLI not found. Please install via:"
  echo "   npm install -g @devcontainers/cli"
  exit 1
fi

# Find all devcontainer.json files in the current directory (recursively)
mapfile -t DEVCONTAINERS < <(find . -type f -name "devcontainer.json")

if [ ${#DEVCONTAINERS[@]} -eq 0 ]; then
  echo "❌ No .devcontainer/devcontainer.json found in this directory."
  exit 1
fi

# Let the user pick one if multiple
if [ ${#DEVCONTAINERS[@]} -gt 1 ]; then
  echo "📦 Found multiple dev containers:"
  for i in "${!DEVCONTAINERS[@]}"; do
    echo "  [$i] ${DEVCONTAINERS[$i]}"
  done
  echo -n "Choose a container [0-${#DEVCONTAINERS[@]}]: "
  read -r choice
else
  choice=0
fi

SELECTED_DEVCONTAINER="${DEVCONTAINERS[$choice]}"
FOLDER_PATH=$(basename "$(dirname $SELECTED_DEVCONTAINER)")

echo "🚀 Starting dev container at: /$SELECTED_DEVCONTAINER"
echo "   Selected container arch is $FOLDER_PATH"
#devcontainer up --workspace-folder $PWD --config "$SELECTED_DEVCONTAINER"

# Grep docker ps output for the matching container name
CONTAINER_ID=$(docker ps --format "{{.ID}} {{.Image}}" | grep "$FOLDER_PATH" | awk '{print $1}' | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Failed to detect the dev container's Docker ID."
  exit 1
else
  echo "Container id found is: ${CONTAINER_ID}"
fi

# Copy setup script into the container
echo "📄 Copying setup.sh into the container..."
docker cp $HOME/Documents/setup_script.sh "$CONTAINER_ID":/tmp/setup.sh
docker exec -u root "$CONTAINER_ID" chmod +x /tmp/setup.sh

# Execute setup script
echo "⚙️ Running setup.sh inside container..."
docker exec -u root -it "$CONTAINER_ID" /tmp/setup.sh

# Get into container
echo "🔧 Dropping into the container..."

# Replace this with your preferred shell, e.g., zsh or bash
docker exec -u root -it "$CONTAINER_ID" zsh
