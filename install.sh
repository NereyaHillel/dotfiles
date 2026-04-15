#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

DOTFILES_DIR="$HOME/.dotfiles"

echo "=> Updating package lists..."
sudo apt update -y

echo "=> Installing core dependencies..."
# xclip is included to ensure Neovim can yank/paste to the system clipboard
# ripgrep is the search engine required by the Neovim Telescope plugin
sudo apt install -y \
  zsh \
  tmux \
  neovim \
  git \
  curl \
  wget \
  xclip \
  ripgrep \
  build-essential

# 1. Set Zsh as the default shell
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "=> Changing default shell to Zsh..."
  chsh -s $(which zsh)
fi

# 2. Install Oh My Zsh (if not already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "=> Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 3. Install Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "=> Installing Tmux Plugin Manager (TPM)..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# 4. Symlink the dotfiles
echo "=> Creating symlinks..."

# Remove existing files to prevent symlink conflicts
rm -rf "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/nvim"

ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

echo "=> Dependencies installed and dotfiles linked!"
echo "=> NOTE: Open tmux and press 'Prefix + I' to install tmux plugins (like vim-tmux-navigator)."
echo "=> NOTE: Open Neovim. Your package manager (Lazy/Packer) will automatically bootstrap and install Telescope, Which-Key, etc."
