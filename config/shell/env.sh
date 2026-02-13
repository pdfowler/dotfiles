# Cross-shell compatible environment variables
# This file is sourced by both interactive and non-interactive shells

# Editor preferences
export EDITOR="vi"
export VISUAL="cursor"

# Automated context detection and configuration
# This section optimizes shell behavior for CI, GitHub Actions, and Cursor Agent contexts
if [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${CURSOR_AGENT:-}" ]]; then
    # Automated context: disable oh-my-zsh for performance and reliability
    export DISABLE_OH_MY_ZSH=true
    
    # Use non-interactive editor for automated contexts
    export EDITOR="cat"
    export GIT_EDITOR="cat"
    export GIT_SEQUENCE_EDITOR="sed -i '' 's/^pick/reword/'"
    
    # Disable interactive features
    export DISABLE_AUTO_UPDATE=true
    export DISABLE_UPDATE_PROMPT=true
else
    # Interactive context: use normal configuration
    export GIT_EDITOR="${GIT_EDITOR:-vi}"
fi

# Note: To use this in your .zshrc, add this conditional loading:
# if [[ -z "$DISABLE_OH_MY_ZSH" ]]; then
#     # Load oh-my-zsh only for interactive shells
#     export ZSH="$HOME/.oh-my-zsh"
#     source "$ZSH/oh-my-zsh.sh"
# fi

# Development tools
export HOMEBREW_NO_ENV_HINTS=true
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export PYENV_ROOT="$HOME/.pyenv"

# NVM configuration (works in all shells)
export NVM_COMPLETION=true
export NVM_LAZY_LOAD=true
export NVM_AUTO_USE=true

# Python/pip configuration
export PIP_REQUIRE_VIRTUALENV=true
export PIP_DOWNLOAD_CACHE="$HOME/.pip/cache"

# Git configuration
export GIT_EDITOR="$EDITOR"

# Oh-my-zsh configuration
# Set oh-my-zsh variables to prevent "parameter not set" errors when nounset is enabled
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$HOME/.oh-my-zsh/cache}"

# Terminal colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad 

## SHIFTSMART
export SHIFTSMART_ROOT="$HOME/Development/shiftsmart"

## NX
export NX_PARALLEL=10

## GT (Graphite/Charcoal CLI) Source
# Unset or "CHARCOAL" = use brew-installed gt (default).
# Set to a path = use that local charcoal repo (e.g. in private.sh: export GT_SOURCE="$HOME/Dev/charcoal").

# Source private configuration (contains sensitive data like API keys, tokens)
# This is also sourced in zshenv, but adding here as backup for cross-shell compatibility
[[ -f ~/.config/shell/private.sh ]] && source ~/.config/shell/private.sh
