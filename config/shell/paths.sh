# Cross-shell compatible PATH modifications
# This file safely adds directories to PATH

# Homebrew setup (macOS)
if [[ -f '/opt/homebrew/bin/brew' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Python/pyenv setup
if [[ -d "$PYENV_ROOT/bin" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Local user binaries
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

# Google Cloud SDK
if [[ -f '/Users/pdfowler/Downloads/google-cloud-sdk/path.zsh.inc' ]]; then
    source '/Users/pdfowler/Downloads/google-cloud-sdk/path.zsh.inc'
fi

# Google Cloud completion (interactive shells only)
if [[ -n "$PS1" ]] && [[ -f '/Users/pdfowler/Downloads/google-cloud-sdk/completion.zsh.inc' ]]; then
    source '/Users/pdfowler/Downloads/google-cloud-sdk/completion.zsh.inc'
fi

# Development tools (add your custom paths here)
# export PATH="$HOME/bin:$PATH" 