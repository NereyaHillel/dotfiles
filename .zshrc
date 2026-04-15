cd
figlet -t -c -d /usr/share/figlet -f ANSI_Shadow "WSL" | lolcat -d 2
fastfetch
# =============================================================================
# 1. POWERLEVEL10K INSTANT PROMPT (Must be at the very top)
# =============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# 2. OH-MY-ZSH CORE CONFIGURATION
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Set the theme to Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Disable bi-weekly auto-update prompts (keeps terminal startup clean)
DISABLE_AUTO_UPDATE="true"

# =============================================================================
# 3. PLUGINS (The "Secret Sauce" of a good shell)
# =============================================================================
# Note: syntax-highlighting and autosuggestions need to be downloaded first
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# 4. ENVIRONMENT VARIABLES
# =============================================================================
# Make Neovim the absolute default editor for everything (including 'cheat')
export EDITOR="nvim"
export VISUAL="nvim"

# =============================================================================
# 5. ALIASES & FUNCTIONS
# =============================================================================
# -- Navigation & Core --
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'
alias cx='chmod +x'

# -- Neovim Shortcuts --
alias v='nvim'
alias vim='nvim'
alias nvim-config='cd ~/.config/nvim/lua/configs && nvim lspconfig.lua'

# -- Compilation & Development --
# C/C++: Compile with strict warnings, memory checks, and modern standards
alias g++='g++ -Wall -Wextra -Werror -std=c++17'
alias runcpp='g++ main.cpp -o out && ./out'

# Python
alias py='python3'

# WSL Specific: Open current directory in Windows Explorer
alias open='explorer.exe .'

# -- Networking & System --
alias pingg='ping -c 4 google.com'
alias myip="ip addr show eth1 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"

# =============================================================================
# 6. POWERLEVEL10K THEME SOURCE (Must be at the very bottom)
# =============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
