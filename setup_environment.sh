#!/bin/bash
set -e

# ──🔍 Detect OS and Package Manager ──────────────────────────────────────────────
detect_package_manager() {
  if command -v apt &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v yum &>/dev/null; then
    echo "yum"
  else
    echo "❌ No supported package manager found." >&2
    exit 1
  fi
}

PKG_MANAGER=$(detect_package_manager)

# ──🧠 Detect Container Environment ───────────────────────────────────────────────
is_container() {
  grep -qaE '(docker|containerd|lxc)' /proc/1/cgroup || [ -f /.dockerenv ]
}

if is_container; then
  echo "📦 Detected container environment"
  export SUDO=""
else
  echo "🖥️ Detected host environment"
  export SUDO="sudo"
fi

# ──🔧 System Update and Core Packages ────────────────────────────────────────────
echo "📦 Updating system..."
$SUDO $PKG_MANAGER -y update || true
$SUDO $PKG_MANAGER -y upgrade || true

echo "📦 Installing base dev tools..."
if [[ "$PKG_MANAGER" == "apt" ]]; then
  $SUDO $PKG_MANAGER install -y \
    curl git unzip zip tar build-essential \
    libssl-dev pkg-config libxcb-shape0-dev \
    libxcb-xfixes0-dev libxkbcommon-dev \
    python3 python3-pip python3-venv \
    zsh tmux ripgrep fd-find fzf lua5.4 luarocks \
    bat cmake libfreetype6-dev libfontconfig1-dev
  if ! is_container; then
    $SUDO $PKG_MANAGER install -y fonts-hack-ttf
  fi
else
  $SUDO $PKG_MANAGER install -y --skip-broken \
    curl git unzip zip tar gcc make \
    openssl-devel pkgconfig \
    xcb-util python3 python3-pip lua luarocks \
    zsh ripgrep fzf cmake fontconfig fontconfig-devel

  # Bat (batcat workaround)
  if ! command -v bat &>/dev/null; then
    $SUDO $PKG_MANAGER install -y bat
  fi

  # fd and fonts need to be handled manually if missing
  if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    echo "⚠️ 'fd' not available; please install manually from https://github.com/sharkdp/fd/releases"
  fi
fi

# ──🧷 Create ~/.local/bin and symlinks ───────────────────────────────────────────
mkdir -p "$HOME/.local/bin"

# bat -> batcat
if ! command -v bat &>/dev/null && [ -f /usr/bin/batcat ]; then
  ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
fi

# fd -> fdfind
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

# ──🦀 Install Rust ──────────────────────────────────────────────────────────────
if ! command -v cargo &>/dev/null; then
  echo "🦀 Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# ──🖼️ Kitty (host only) ─────────────────────────────────────────────────────
if ! is_container && ! command -v kitty &>/dev/null; then
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
fi

# ──🧭 eza ────────────────────────────────────────────────────────────────────────
if ! command -v eza &>/dev/null; then
  cargo install eza
fi

# ──🧭 tms ────────────────────────────────────────────────────────────────────────
if ! command -v tms &>/dev/null; then
  cargo install tms
fi

# ──📁 zoxide ─────────────────────────────────────────────────────────────────────
if ! command -v zoxide &>/dev/null; then
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# ──📁 yazi ─────────────────────────────────────────────────────────────────────
if ! command -v yazi &>/dev/null; then
  cargo install --locked --force yazi-build
fi

# ──📝 Neovim (latest) ────────────────────────────────────────────────────────────
if ! command -v nvim &>/dev/null; then
  echo "Installing neovim!!!"
  # Clone the Neovim repository
  git clone https://github.com/neovim/neovim.git
  cd neovim
  # Checkout the desired version
  git checkout v0.11.5
  # Build Neovim
  make CMAKE_BUILD_TYPE=Release
  # Install Neovim
  $SUDO make install
fi

# ──🧲 LazyGit ────────────────────────────────────────────────────────────────────
if ! command -v lazygit &>/dev/null; then
  echo "Install lazygit!!!"
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION#v}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  $SUDO install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
fi

# ──🔵    Lazy Docker   ─────────────────────────────────────────────────────────────
if ! is_container && ! command -v lazydocker &>/dev/null; then
  echo "Installing lazydocker!!!"
  curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
fi

# ──🧷  rofi ─────────────────────────────────────────────────────────────
if ! is_container && ! command -v rofi &>/dev/null; then
  echo "Installing rofi!!!"
  $SUDO $PKG_MANAGER install -y rofi
fi

# ──🧠 PathPicker ─────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.pathpicker" ]; then
  echo "Installing PathPicker!!!"
  git clone https://github.com/facebook/PathPicker.git "$HOME/.pathpicker"
  $SUDO ln -sf "$HOME/.pathpicker/fpp" /usr/local/bin/fpp
fi

# ──💎 Ruby ───────────────────────────────────────────────────────────────────────
if ! command -v ruby &>/dev/null; then
  echo "Installing Ruby!!!"
  $SUDO $PKG_MANAGER install -y ruby ruby-devel || $SUDO $PKG_MANAGER install -y ruby-full
fi

# ──🔤 Nerd Font (host only) ──────────────────────────────────────────────────────
if ! is_container && [ ! -f "$HOME/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" ]; then
  echo "Installing Nerd Fonts"
  mkdir -p "$HOME/.local/share/fonts"
  curl -Lo "$HOME/.local/share/fonts/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
  unzip -o "$HOME/.local/share/fonts/Hack.zip" -d "$HOME/.local/share/fonts/Hack"
  fc-cache -fv
  rm "$HOME/.local/share/fonts/Hack.zip"
fi

# ──🧙 oh-my-zsh ──────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh"
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ──🧙 starship ──────────────────────────────────────────────────────────────────
if ! command -v starship &>/dev/null; then
  echo "Installing starship"
  curl -sS https://starship.rs/install.sh | sh
fi

# ──🟢 NVM + Node + npm ───────────────────────────────────────────────────────────
if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
  echo "Installing NVM!!!"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
fi

# ──🧰 Devcontainer CLI ───────────────────────────────────────────────────────────
if ! command -v devcontainer &>/dev/null; then
  echo "Installing devcontainers!!!"
  npm install -g @devcontainers/cli
fi

echo "✅ Environment setup complete."
