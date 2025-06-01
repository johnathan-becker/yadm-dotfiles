#!/bin/bash
set -e

# Detect if running in a container
is_container() {
  grep -qaE '(docker|containerd|lxc)' /proc/1/cgroup || [ -f /.dockerenv ]
}

echo "🛠️ Beginning environment setup..."

if ! is_container; then
  export SUDO=sudo
else
  export SUDO=
fi

if is_container; then
  echo "📦 Detected container environment"

  # Copy dotfiles from mounted volume if available
  if [ -d /dotfiles ]; then
    echo "📁 Copying dotfiles from /dotfiles..."
    cp -rf /dotfiles/.[!.]* "$HOME"/ || true
    cp -rf /dotfiles/.config/* "$HOME/.config/" || true
  fi
else
  echo "🖥️ Detected local machine"
fi

echo "📦 Updating system..."
$SUDO apt update && $SUDO apt upgrade -y

echo "📦 Installing core packages..."
$SUDO apt install -y \
  curl git unzip zip tar build-essential \
  libssl-dev pkg-config libxcb-shape0-dev \
  libxcb-xfixes0-dev libxkbcommon-dev \
  python3 python3-pip python3-venv \
  zsh tmux ripgrep fd-find fzf \
  bat cmake libfreetype6-dev libfontconfig1-dev

# Fonts only on host
if ! is_container; then
  $SUDO apt install -y fonts-hack-ttf
fi

# Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# Create bat -> batcat symlink
if ! command -v bat &>/dev/null && [ -f /usr/bin/batcat ]; then
  echo "🔗 Creating bat -> batcat symlink..."
  ln -sf /usr/bin/batcat ~/.local/bin/bat
else
  echo "📄 bat already available."
fi

# Symlink fd if needed
if ! command -v fd &>/dev/null; then
  ln -sf "$(which fdfind)" ~/.local/bin/fd
fi

# 🦀 Rust
if ! command -v cargo &>/dev/null; then
  echo "🦀 Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "🦀 Rust already installed"
fi

# 🖼️ Alacritty (only on host)
if ! is_container && ! command -v alacritty &>/dev/null; then
  echo "🖼️ Installing Alacritty..."
  cargo install alacritty
else
  echo "🖼️ Skipping Alacritty in container or already installed"
fi

# 🧭 eza
if ! command -v eza &>/dev/null; then
  echo "🧭 Installing eza..."
  cargo install eza
else
  echo "🧭 eza already installed"
fi

# 📁 zoxide
if ! command -v zoxide &>/dev/null; then
  echo "📁 Installing zoxide..."
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
  echo "📁 zoxide already installed"
fi

# 📝 Neovim (latest)
if ! command -v nvim &>/dev/null; then
  echo "📝 Installing latest Neovim..."
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  $SUDO rm -rf /opt/nvim
  $SUDO tar -C /opt -xzf nvim-linux-x86_64.tar.gz
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
else
  echo "📝 Neovim already installed"
fi

# 🧲 LazyGit
if ! command -v lazygit &>/dev/null; then
  echo "🧲 Installing LazyGit..."
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  $SUDO install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
else
  echo "🧲 LazyGit already installed"
fi

# 🧠 PathPicker
if [ ! -d "$HOME/.pathpicker" ]; then
  echo "🧠 Installing PathPicker..."
  git clone https://github.com/facebook/PathPicker.git ~/.pathpicker
  $SUDO ln -sf ~/.pathpicker/fpp /usr/local/bin/fpp
else
  echo "🧠 PathPicker already installed"
fi

# 🔵 Lua + LuaRocks
if ! command -v luarocks &>/dev/null; then
  echo "🔵 Installing Lua + LuaRocks..."
  $SUDO apt install -y lua5.4 luarocks
else
  echo "🔵 Lua + LuaRocks already installed"
fi

# 💎 Ruby
if ! command -v ruby &>/dev/null; then
  echo "💎 Installing Ruby..."
  $SUDO apt install -y ruby-full
else
  echo "💎 Ruby already installed"
fi

# 🔤 Nerd Font (only on host)
if ! is_container && [ ! -f "$HOME/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" ]; then
  echo "🔤 Installing Hack Nerd Font..."
  mkdir -p "$HOME/.local/share/fonts"
  curl -Lo "$HOME/.local/share/fonts/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
  unzip -o "$HOME/.local/share/fonts/Hack.zip" -d "$HOME/.local/share/fonts/Hack"
  fc-cache -fv
  rm "$HOME/.local/share/fonts/Hack.zip"
else
  echo "🔤 Skipping font install (already installed or in container)"
fi

# 🧙 oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🧙 Installing oh-my-zsh..."
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "🧙 oh-my-zsh already installed"
fi

# 🪟 oh-my-tmux
if [ ! -d "$HOME/.config/tmux" ]; then
  echo "🪟 Installing oh-my-tmux..."
  git clone --single-branch https://github.com/gpakosz/.tmux.git ~/oh-my-tmux
  mkdir -p ~/.config/tmux
  ln -sf ~/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf
  cp ~/oh-my-tmux/.tmux.conf.local ~/.config/tmux/tmux.conf.local
else
  echo "🪟 oh-my-tmux already installed"
fi

# 🎨 Alacritty Dracula Theme (host only)
if ! is_container; then
  echo "🎨 Setting up Alacritty with Dracula theme (TOML)..."
  ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
  DRACULA_TOML="$ALACRITTY_CONFIG_DIR/dracula.toml"
  mkdir -p "$ALACRITTY_CONFIG_DIR"
  if [ ! -f "$DRACULA_TOML" ]; then
    curl -sLo "$DRACULA_TOML" https://raw.githubusercontent.com/dracula/alacritty/master/dracula.toml
  else
    echo "🎨 Dracula theme already present."
  fi
fi

# 🧠 LazyVim
echo "🧠 Setting up LazyVim..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
  rm -rf "$NVIM_CONFIG_DIR/.git"
  nvim --headless "+Lazy! sync" +qa
else
  echo "🧠 LazyVim already exists. Skipping setup."
fi

# 🟢 Install NVM + Node (LTS) + npm
if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
  echo "🟢 Installing NVM, Node.js, and npm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  # Source NVM (safe for both bash/zsh)
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts
else
  echo "🟢 Node.js and npm already installed"
fi

# 🧰 Install devcontainer CLI
if ! command -v devcontainer &>/dev/null; then
  echo "🧰 Installing devcontainer CLI..."
  npm install -g @devcontainers/cli
else
  echo "🧰 devcontainer CLI already installed"
fi

echo "✅ Environment setup complete."
