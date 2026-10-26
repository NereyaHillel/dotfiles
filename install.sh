#!/usr/bin/env bash
# Exit immediately on error, unset variable, or failed pipe
set -euo pipefail

# ==========================================
# Variables & Colors
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

info()    { echo -e "${YELLOW}=> $1${NC}"; }
success() { echo -e "${GREEN}[✔] $1${NC}"; }
error()   { echo -e "${RED}[✘] $1${NC}"; }

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Dotfiles Installation & Setup Script ${NC}"
echo -e "${BLUE}=======================================${NC}\n"

# ==========================================
# 1. Environment Detection
# ==========================================
info "Detecting environment..."
IS_TERMUX=false
IS_WSL=false

if [[ "${PREFIX:-}" == *"com.termux"* ]]; then
    IS_TERMUX=true
    success "Termux environment detected."
elif grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
    IS_WSL=true
    success "WSL (Windows Subsystem for Linux) environment detected."
else
    success "Standard Linux environment detected."
fi

# ==========================================
# 2. Package Installation
# ==========================================
echo ""
info "Updating package lists..."
if [ "$IS_TERMUX" = true ]; then
    pkg update -y
else
    sudo apt-get update -y
fi

info "Installing core dependencies..."
COMMON_PACKAGES="zsh tmux neovim git curl wget ripgrep direnv fzf nodejs"

if [ "$IS_TERMUX" = true ]; then
    # Termux packages both gh and lazygit natively
    TERMUX_PACKAGES="$COMMON_PACKAGES python build-essential termux-api clang make fd bat gh lazygit"
    pkg install -y $TERMUX_PACKAGES

    if [ ! -d "$HOME/storage" ]; then
        info "Setting up Termux storage access..."
        termux-setup-storage || true
    fi
else
    # Linux / WSL specific packages
    LINUX_PACKAGES="$COMMON_PACKAGES python3 python-is-python3 build-essential xclip python3-venv python3-pip fd-find bat tar"
    sudo apt-get install -y $LINUX_PACKAGES

    # Normalize Ubuntu/Debian binary names (fdfind -> fd, batcat -> bat)
    mkdir -p "$HOME/.local/bin"
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        success "Aliased fdfind -> ~/.local/bin/fd"
    fi
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        success "Aliased batcat -> ~/.local/bin/bat"
    fi

    # ------------------------------------------
    # Install GitHub CLI (gh) on Linux / WSL
    # ------------------------------------------
    if ! command -v gh >/dev/null 2>&1; then
        info "Installing GitHub CLI (gh)..."
        if sudo apt-get install -y gh >/dev/null 2>&1; then
            success "GitHub CLI (gh) installed via apt."
        else
            sudo mkdir -p -m 755 /etc/apt/keyrings
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
            sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
            sudo apt-get update -y
            sudo apt-get install -y gh
            success "GitHub CLI (gh) installed via official GitHub repo."
        fi
    else
        success "GitHub CLI (gh) is already installed."
    fi

    # ------------------------------------------
    # Install Lazygit on Linux / WSL
    # ------------------------------------------
    if ! command -v lazygit >/dev/null 2>&1; then
        info "Installing latest Lazygit release..."
        ARCH="$(uname -m)"
        case "$ARCH" in
            x86_64)        LG_ARCH="x86_64" ;;
            aarch64|arm64) LG_ARCH="arm64" ;;
            *)             LG_ARCH="x86_64" ;;
        esac

        LAZYGIT_VERSION="$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')"
        TMP_DIR="$(mktemp -d)"
        curl -fsSL -o "$TMP_DIR/lazygit.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LG_ARCH}.tar.gz"
        tar -xzf "$TMP_DIR/lazygit.tar.gz" -C "$TMP_DIR" lazygit
        sudo install "$TMP_DIR/lazygit" -D -t /usr/local/bin/
        rm -rf "$TMP_DIR"
        success "Lazygit v${LAZYGIT_VERSION} installed to /usr/local/bin/lazygit."
    else
        success "Lazygit is already installed."
    fi
fi
success "Dependencies installed."

# ==========================================
# 3. Default Shell Setup
# ==========================================
echo ""
info "Setting Zsh as default shell..."
if [ "$IS_TERMUX" = true ]; then
    chsh -s zsh || true
    success "Zsh set as default shell."
else
    ZSH_PATH="$(command -v zsh)"
    if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
        sudo chsh -s "$ZSH_PATH" "$USER" || chsh -s "$ZSH_PATH" || true
        success "Zsh set as default shell ($ZSH_PATH)."
    else
        success "Zsh is already the default shell."
    fi
fi

# ==========================================
# 4. Plugin Managers (Zinit & TPM)
# ==========================================
echo ""
info "Installing Zinit (Zsh Plugin Manager)..."
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    success "Zinit installed successfully."
else
    git -C "$ZINIT_HOME" pull --ff-only >/dev/null 2>&1 || true
    success "Zinit is already installed (and up to date)."
fi

echo ""
info "Installing Tmux Plugin Manager (TPM)..."
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    success "TPM installed successfully."
else
    git -C "$TPM_DIR" pull --ff-only >/dev/null 2>&1 || true
    success "TPM is already installed (and up to date)."
fi

# ==========================================
# 5. Symlinking Config Files
# ==========================================
echo ""
info "Creating symlinks from $DOTFILES_DIR..."

link_file() {
    local src="$1"
    local dst="$2"

    if [ ! -e "$src" ]; then
        error "Source $src does not exist — skipping."
        return 0
    fi

    mkdir -p "$(dirname "$dst")"

    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        local backup="${dst}.bak.${BACKUP_SUFFIX}"
        info "Backing up existing $dst -> $backup"
        mv "$dst" "$backup"
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    ln -s "$src" "$dst"
    success "Linked $dst -> $src"
}

link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# Optional: Link lazygit config if you store one in your dotfiles
if [ -e "$DOTFILES_DIR/.config/lazygit" ]; then
    link_file "$DOTFILES_DIR/.config/lazygit" "$HOME/.config/lazygit"
fi

# ==========================================
# 6. Automated Plugin Bootstrapping
# ==========================================
echo ""
info "Bootstrapping Tmux plugins via TPM..."
if [ -x "$TPM_DIR/bin/install_plugins" ]; then
    "$TPM_DIR/bin/install_plugins" || true
    success "Tmux plugins installed automatically."
fi

if command -v nvim >/dev/null 2>&1 && [ -e "$HOME/.config/nvim" ]; then
    echo ""
    info "Syncing Neovim plugins headlessly (Lazy.nvim)..."
    nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true
    success "Neovim plugins synced."
fi

# ==========================================
# 7. Completion
# ==========================================
echo -e "\n${BLUE}=======================================${NC}"
echo -e "${GREEN}        Installation Complete!         ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo -e "=> ${YELLOW}Next step 1:${NC} Run 'gh auth login' to authenticate GitHub CLI & Git credentials."
echo -e "=> ${YELLOW}Next step 2:${NC} Run 'exec zsh' to enter your configured shell."
