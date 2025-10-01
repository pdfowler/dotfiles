# Cross-shell compatible environment variables
# This file is sourced by both interactive and non-interactive shells

# Editor preferences
export EDITOR="vi"
export VISUAL="cursor"

# Development tools
export HOMEBREW_NO_ENV_HINTS=true
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

# Source private configuration (contains sensitive data like API keys, tokens)
# This is also sourced in zshenv, but adding here as backup for cross-shell compatibility
[[ -f ~/.config/shell/private.sh ]] && source ~/.config/shell/private.sh
