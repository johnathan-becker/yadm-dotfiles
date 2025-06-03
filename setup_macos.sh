#!/bin/bash
set -e

# ──🔍 Detect OS ────────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  echo "❌ This script is intended for macOS only."
  exit 1
fi

# ──🔧 Ensure Homebrew ───────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ──📦 Update Homebrew ───────────────────────────────────────────────────────────
echo "📦 Updating Homebrew..."
brew update
brew upgrade

# ──📦 Install base packages ─────────────────────────────────────────────────────
echo "📦 Installing core utilities..."
brew install \
  curl git unzip zip cmake make \
  openssl pkg-config python@3 zsh tmux \
  ripgrep fd fzf lua luarocks \
  bat fontconfig ruby node npm

# ──🧷 Ensure ~/.local/bin and symlinks ──────────────────────────────────────────
mkdir -p "$HOME/.local/bin"

# Symlink bat if needed (macOS usually installs it directly)
if ! command -v bat &>/dev/null && [ -f "$(brew --prefix)/bin/bat" ]; then
  ln -sf "$(brew --prefix)/bin/bat" "$HOME/.local/bin/bat"
fi

# fd should already be 'fd' on macOS
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ──🦀 Rust ──────────────────────────────────────────────────────────────────────
if ! command -v &>/dev/null; then
  echo "🦀 Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# ──🖼️ Alacritty ─────────────────────────────────────────────────────────────────
if ! command -v alacritty &>/dev/null; then
  git clone https://github.com/alacritty/alacritty.git
  cd alacritty
  rustup target add x86_64-apple-darwin aarch64-apple-darwin
  make app-universal
  cp -r target/release/osx/Alacritty.app /Applications/
fi

# ──🧭 eza ───────────────────────────────────────────────────────────────────────
if ! command -v eza &>/dev/null; then
  cargo install eza
fi

# ──📁 zoxide ─────────────────────────────────────────────────────────────────────
if ! command -v zoxide &>/dev/null; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ──📝 Neovim ────────────────────────────────────────────────────────────────────
if ! command -v nvim &>/dev/null; then
  echo "📝 Installing Neovim from source..."
  git clone https://github.com/neovim/neovim.git
  cd neovim
  git checkout v0.11.0
  make CMAKE_BUILD_TYPE=Release
  sudo make install
  cd ..
  rm -rf neovim
fi

# ──🧲 LazyGit ───────────────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Darwin_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
fi

# ──🧠 PathPicker ────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.pathpicker" ]; then
  git clone https://github.com/facebook/PathPicker.git "$HOME/.pathpicker"
  sudo ln -sf "$HOME/.pathpicker/fpp" /usr/local/bin/fpp
fi

# ──🔤 Nerd Font ─────────────────────────────────────────────────────────────────
FONT_DIR="$HOME/Library/Fonts"
if [ ! -f "$FONT_DIR/Hack Regular Nerd Font Complete.ttf" ]; then
  mkdir -p "$FONT_DIR"
  curl -Lo "$FONT_DIR/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
  unzip -o "$FONT_DIR/Hack.zip" -d "$FONT_DIR"
  rm "$FONT_DIR/Hack.zip"
  echo "✅ Hack Nerd Font installed."
fi

# ──🧙 oh-my-zsh ──────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ──🪟 oh-my-tmux ────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.config/tmux" ]; then
  git clone https://github.com/gpakosz/.tmux.git "$HOME/oh-my-tmux"
  mkdir -p "$HOME/.config/tmux"
  ln -sf "$HOME/oh-my-tmux/.tmux.conf" "$HOME/.config/tmux/tmux.conf"
  cp "$HOME/oh-my-tmux/.tmux.conf.local" "$HOME/.config/tmux/tmux.conf.local"
fi

# ──🎨 Alacritty Dracula Theme ───────────────────────────────────────────────────
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
DRACULA_TOML="$ALACRITTY_CONFIG_DIR/dracula.toml"
mkdir -p "$ALACRITTY_CONFIG_DIR"
if [ ! -f "$DRACULA_TOML" ]; then
  curl -sLo "$DRACULA_TOML" https://raw.githubusercontent.com/dracula/alacritty/master/dracula.toml
fi

# ──🧠 LazyVim ────────────────────────────────────────────────────────────────────
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_CONFIG_DIR" ]; then
  git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"
  rm -rf "$NVIM_CONFIG_DIR/.git"
  nvim --headless "+Lazy! sync" +qa
fi

# ──🧰 Devcontainer CLI ───────────────────────────────────────────────────────────
if ! command -v devcontainer &>/dev/null; then
  npm install -g @devcontainers/cli
fi

echo "✅ macOS environment setup complete."
