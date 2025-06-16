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

# Terminal colors
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad 

## SHIFTSMART
export SHIFTSMART_ROOT="$HOME/Development/shiftsmart"
