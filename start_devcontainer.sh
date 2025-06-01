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
FOLDER_PATH=$(basename "$(dirname "$SELECTED_DEVCONTAINER")")

# Check if a matching container is already running
CONTAINER_ID=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}" | grep "$FOLDER_PATH" | awk '{print $1}' | head -n 1)

if [ -n "$CONTAINER_ID" ]; then
  echo "✅ Container for '$FOLDER_PATH' is already running: $CONTAINER_ID"
  echo "🔧 Dropping into the running container..."
  docker exec -it "$CONTAINER_ID" zsh
  exit 0
fi

# If not running, continue with devcontainer up
echo "🚀 Starting dev container at: /$SELECTED_DEVCONTAINER"
echo "   Selected container arch is $FOLDER_PATH"
devcontainer up --workspace-folder "$PWD" --config "$SELECTED_DEVCONTAINER"

# Re-fetch the container ID
CONTAINER_ID=$(docker ps --format "{{.ID}} {{.Image}} {{.Names}}" | grep "$FOLDER_PATH" | awk '{print $1}' | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Failed to detect the dev container's Docker ID."
  exit 1
else
  echo "Container id found is: ${CONTAINER_ID}"
fi

# Copy setup script into the container
echo "📄 Copying setup.sh into the container..."
docker cp "$HOME/setup_environment.sh" "$CONTAINER_ID":/tmp/setup.sh
docker exec "$CONTAINER_ID" chmod +x /tmp/setup.sh

# Execute setup script
echo "⚙️ Running setup.sh inside container..."
docker exec -it "$CONTAINER_ID" /tmp/setup.sh

# Sync dotfiles
echo "🗃️ Syncing dotfiles via yadm list..."

if ! command -v yadm &>/dev/null; then
  echo "❌ yadm not found on host. Skipping dotfile sync."
else
  while IFS= read -r file; do
    src="$HOME/$file"
    dest="/root/$file"
    echo "📁 Copying: $file from ${src} to ${dest}"
    docker exec "$CONTAINER_ID" mkdir -p "$(dirname "$dest")"
    docker cp "$src" "$CONTAINER_ID":"$dest"
  done < <(yadm list -a)
fi

# Get into container
echo "🔧 Dropping into the container..."
docker exec -it "$CONTAINER_ID" zsh
