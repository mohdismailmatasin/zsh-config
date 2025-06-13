# Performance: Add local bin paths to PATH
export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="suprima-asra"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Performance optimizations
zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 13
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_AUTO_TITLE="false"
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"  # Faster git status for large repos
HIST_STAMPS="yyyy-mm-dd"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Optimized plugin loading - ordered by importance and performance
plugins=(
    git                              # Essential git integration
    zsh-autocomplete                # Fast autocomplete
    zsh-autosuggestions            # Fast autosuggestions
    zsh-completions               # Additional completions
    zsh-history-substring-search   # Better history search
    zsh-syntax-highlighting         # Must be loaded last for performance
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
# ENVIRONMENT CONFIGURATION
# ============================================================================

# Hide default virtual environment prompt (we use custom one in RPROMPT)
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Preferred editor (auto-detect best available)
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
elif command -v vim &> /dev/null; then
    export EDITOR='vim'
    export VISUAL='vim'
else
    export EDITOR='nano'
    export VISUAL='nano'
fi

# Language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Less configuration for better paging
export LESS='-R -i -M -S -z-4'
export PAGER='less'

# ============================================================================
# ALIASES AND SHORTCUTS
# ============================================================================

# Enhanced lsd aliases (with fallback to ls if lsd not available)
if command -v lsd &> /dev/null; then
    alias ls='lsd'
    alias l='lsd -l'
    alias la='lsd -A'
    alias lla='lsd -lA'
    alias lt='lsd --tree'
    alias lr='lsd -lR'
else
    alias l='ls -l'
    alias la='ls -A'
    alias lla='ls -lA'
    alias lr='ls -lR'
fi

# System shortcuts
alias c='clear'
alias h='history'
alias j='jobs'
alias v='$EDITOR'
alias e='$EDITOR'

# Enhanced cd aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Quick config edits
alias zshconfig='$EDITOR ~/.zshrc'
alias ohmyzsh='$EDITOR ~/.oh-my-zsh'
alias vimrc='$EDITOR ~/.vimrc'

# Network and system info
alias myip='curl -s http://ipinfo.io/ip'
alias localip="ip route get 1.1.1.1 | grep -oP 'src \K\S+'"
alias ports='netstat -tuln'
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Git shortcuts (complementing oh-my-zsh git plugin)
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias glog='git log --oneline --graph --decorate'

# Project-specific aliases
alias pactools='cd ~/Documents/Project/pacman-tools/ && ./main.sh'

# ============================================================================
# PYTHON ENVIRONMENT MANAGEMENT
# ============================================================================

# Optimized Python environment auto-activation
PYTHON_ENV_PATH="$HOME/.python-env"

# Cache for environment check to improve performance
_python_env_checked=""

activate_python_env_if_needed() {
    # Only check if environment exists once per session
    if [[ -z "$_python_env_checked" ]]; then
        if [[ -d "$PYTHON_ENV_PATH" ]]; then
            _python_env_checked="exists"
        else
            _python_env_checked="not_found"
            return 0
        fi
    fi
    
    # Skip if environment doesn't exist
    [[ "$_python_env_checked" == "not_found" ]] && return 0
    
    # Check if virtual environment is not already activated
    if [[ "$VIRTUAL_ENV" != "$PYTHON_ENV_PATH" ]]; then
        echo " Auto-activating User Python Environment..."
        source "$PYTHON_ENV_PATH/bin/activate"
    fi
}

# Wrapper functions for Python commands
for cmd in python python3 pip pip3; do
    eval "${cmd}() {
        activate_python_env_if_needed
        command ${cmd} \"\$@\"
    }"
done

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and kill process by name
killprocess() {
    ps aux | grep -i $1 | grep -v grep | awk '{print $2}' | xargs sudo kill -9
}

# Quick file search
ff() {
    find . -type f -name "*$1*"
}

# Quick directory search
fd() {
    find . -type d -name "*$1*"
}

# Weather function (requires curl)
weather() {
    local city="${1:-}"
    curl -s "wttr.in/${city}?format=3"
}

# ============================================================================
# PERFORMANCE OPTIMIZATIONS
# ============================================================================

# Disable Oh My Zsh auto-update check on every shell start
zstyle ':omz:update' mode reminder

# Faster completion system
autoload -Uz compinit
# Only regenerate compdump once a day
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit -d "${ZDOTDIR:-$HOME}/.zcompdump"
else
    compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
fi

# Load completions for commonly used commands
if command -v docker &> /dev/null; then
    # Docker completion will be loaded by oh-my-zsh if available
fi

if command -v kubectl &> /dev/null; then
    # Kubernetes completion (uncomment if needed)
    # source <(kubectl completion zsh)
fi

# ============================================================================
# FINAL CONFIGURATIONS
# ============================================================================

# Load any local customizations (if they exist)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Load any work-specific configurations
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work
