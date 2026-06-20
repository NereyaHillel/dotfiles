# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==========================
# 1. ZINIT CONFIGURATION
# ==========================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# -> STEP 1: Add extra completions to the system
zinit light zsh-users/zsh-completions

# -> STEP 2: Start the completion engine natively (This fixes the file/folder bug!)
autoload -Uz compinit
compinit
zmodload zsh/complist

# -> STEP 3: Configure the interactive Tab Menu
zstyle ':completion:*' menu select=2
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
bindkey -M menuselect '^[[Z' reverse-menu-complete

# -> STEP 4: Load plugins that hook into the completion engine
zinit snippet OMZL::history.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::key-bindings.zsh
zinit snippet OMZL::theme-and-appearance.zsh

zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::dirhistory
zinit snippet OMZP::copypath
zinit snippet OMZP::copyfile

# -> STEP 5: Visuals load absolutely last
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit ice depth=1; zinit light romkatv/powerlevel10k


# ==========================
# 2. USER ENVIRONMENT
# ==========================
export DOTFILES="$HOME/.dotfiles"
export PATH="$HOME/.mybin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Development Environment Setup
eval "$(direnv hook zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# History settings
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY


# ==========================
# 3. ALIASES & FUNCTIONS
# ==========================
alias python=python3
alias pip=pip3
alias c=clear
alias ..='cd ..'
alias ...='cd ../..'

# Git & Docker
alias g=git
alias gs='git status'
alias gp='git pull'
alias gpu='git push'
alias gc='git commit'
alias gco='git checkout'
alias d=docker
alias dc=docker-compose

# Directory navigation
unalias md 2>/dev/null
md() { mkdir -p "$1" && cd "$1" }

# Python virtual environments
venv() {
    local venv_path=$(find . -type d \( -name "venv" -o -name ".venv" \) -print -quit)
    if [[ -n "$venv_path" ]]; then
        source "$venv_path/bin/activate"
        echo "Activated virtual environment in $venv_path"
    else
        echo "No virtual environment found"
    fi
}

mkproject() {
    local project_name="$1"
    local project_type="${2:-python}"

    if [[ -z "$project_name" ]]; then echo "Please provide a project name"; return 1; fi
    mkdir -p "$project_name" && cd "$project_name"

    case "$project_type" in
        python)
            python3 -m venv .venv
            source .venv/bin/activate
            touch README.md pyproject.toml
            echo "Created Python project: $project_name"
            ;;
        rust)
            cargo new "$project_name"
            cd "$project_name"
            echo "Created Rust project: $project_name"
            ;;
        *) echo "Unsupported project type. Use 'python' or 'rust'"; return 1 ;;
    esac
}


# ==========================
# 4. FINAL EXECUTION
# ==========================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Background crond
(pgrep -x "crond" >/dev/null || crond) &> /dev/null &

export COPILOT_NODE_COMMAND="/data/data/com.termux/files/usr/bin/node"
