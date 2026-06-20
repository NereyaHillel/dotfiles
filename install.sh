#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# Variables & Colors
# ==========================================
DOTFILES_DIR="$HOME/.dotfiles"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Dotfiles Installation & Setup Script ${NC}"
echo -e "${BLUE}=======================================${NC}\n"

# ==========================================
# 1. Environment Detection
# ==========================================
echo -e "${YELLOW}=> Detecting environment...${NC}"
if [[ "$PREFIX" == *com.termux* ]]; then
    IS_TERMUX=true
    echo -e "${GREEN}[✔] Termux environment detected.${NC}"
else
    IS_TERMUX=false
    echo -e "${GREEN}[✔] Standard Linux environment detected.${NC}"
fi

# ==========================================
# 2. Package Installation
# ==========================================
echo -e "\n${YELLOW}=> Updating package lists...${NC}"
if [ "$IS_TERMUX" = true ]; then
    pkg update -y
else
    sudo apt update -y
fi

echo -e "${YELLOW}=> Installing core dependencies...${NC}"
# Added fzf, nodejs, and python to support your .zshrc and Copilot
PACKAGES="zsh tmux neovim git curl wget ripgrep direnv fzf nodejs python"

if [ "$IS_TERMUX" = true ]; then
    # Added clang and make for native Termux module compiling (LSPs/treesitter)
    PACKAGES="$PACKAGES build-essential termux-api clang make"
    pkg install -y $PACKAGES
else
    # Linux specific: uses xclip for clipboard and requires sudo
    PACKAGES="$PACKAGES build-essential xclip python3-venv"
    sudo apt install -y $PACKAGES
fi
echo -e "${GREEN}[✔] Dependencies installed.${NC}"

# ==========================================
# 3. Default Shell Setup
# ==========================================
echo -e "\n${YELLOW}=> Setting Zsh as default shell...${NC}"
if [ "$IS_TERMUX" = true ]; then
    # The || true prevents set -e from killing the script if chsh returns a warning
    chsh -s zsh || true
    echo -e "${GREEN}[✔] Zsh set as default shell.${NC}"
else
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)" || true
        echo -e "${GREEN}[✔] Zsh set as default shell.${NC}"
    else
        echo -e "${GREEN}[✔] Zsh is already the default shell.${NC}"
    fi
fi

# ==========================================
# 4. Plugin Managers (Zinit & TPM)
# ==========================================
echo -e "\n${YELLOW}=> Installing Zinit (Zsh Plugin Manager)...${NC}"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    echo -e "${GREEN}[✔] Zinit installed successfully.${NC}"
else
    echo -e "${GREEN}[✔] Zinit is already installed.${NC}"
fi

echo -e "\n${YELLOW}=> Installing Tmux Plugin Manager (TPM)...${NC}"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo -e "${GREEN}[✔] TPM installed successfully.${NC}"
else
    echo -e "${GREEN}[✔] TPM is already installed.${NC}"
fi

# ==========================================
# 5. Symlinking Config Files
# ==========================================
echo -e "\n${YELLOW}=> Creating symlinks...${NC}"

# Helper function to safely backup and link files
link_file() {
    local src=$1
    local dst=$2

    # If the destination exists and is NOT a symlink, back it up
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo -e "${YELLOW}   Backing up existing $dst to ${dst}.bak${NC}"
        mv "$dst" "${dst}.bak"
    # If it is a symlink, just remove it to update it
    elif [ -L "$dst" ]; then
        rm "$dst"
    fi

    ln -sf "$src" "$dst"
    echo -e "${GREEN}[✔] Linked $dst -> $src${NC}"
}

# Ensure target directories exist
mkdir -p "$HOME/.config"

link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# ==========================================
# 6. Completion
# ==========================================
echo -e "\n${BLUE}=======================================${NC}"
echo -e "${GREEN}    Installation Complete!    ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo -e "=> ${YELLOW}NOTE 1:${NC} Restart your terminal or type 'exec zsh' to trigger the initial Zinit compilation."
echo -e "=> ${YELLOW}NOTE 2:${NC} Open tmux and press 'Prefix + I' to install tmux plugins."
echo -e "=> ${YELLOW}NOTE 3:${NC} Open Neovim to let Lazy automatically bootstrap your tools."

