# Cross-shell compatible PATH modifications
# This file safely adds directories to PATH

# Ensure core utilities and essential paths are always available FIRST
# This must be done before any other PATH modifications to avoid "command not found" errors
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Verify core utilities are available
if ! command -v tr >/dev/null 2>&1 || ! command -v tail >/dev/null 2>&1 || ! command -v head >/dev/null 2>&1 || ! command -v sed >/dev/null 2>&1; then
    echo "Warning: Core utilities not found in PATH. Current PATH: $PATH"
    # Try to add system paths if they're missing
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

# Safe NVM loading function
safe_load_nvm() {
    # Ensure core utilities are available
    if command -v tr >/dev/null 2>&1 && command -v tail >/dev/null 2>&1 && command -v head >/dev/null 2>&1 && command -v sed >/dev/null 2>&1; then
        if [[ -d "$HOME/.nvm" ]] && ! command -v nvm >/dev/null 2>&1; then
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            return 0
        fi
    else
        echo "Warning: Core utilities not available, NVM not loaded"
        return 1
    fi
    return 0
}

# Fix NVM hook PATH issues by ensuring core utilities are available
fix_nvm_hook_path() {
    # Check if we're in a context where core utilities might not be available
    if ! command -v tr >/dev/null 2>&1 || ! command -v tail >/dev/null 2>&1 || ! command -v head >/dev/null 2>&1 || ! command -v sed >/dev/null 2>&1; then
        # Ensure core utilities are available
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    fi
}

# Function to clean up NVM from PATH
clean_nvm_path() {
    # Remove NVM-related paths from PATH
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.nvm" | tr '\n' ':' | sed 's/:$//')
    # Also remove NVM environment variables
    unset NVM_BIN NVM_INC NVM_DIR
}

# Homebrew setup (macOS)
if [[ -f '/opt/homebrew/bin/brew' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Local user binaries
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Node.js and NVM setup (following Shiftsmart best practices)
# Only load NVM if core utilities are available and NVM is properly installed
if [[ -d "$HOME/.nvm" ]] && [[ -f "$HOME/.nvm/nvm.sh" ]]; then
    # Clean up any existing NVM paths first
    clean_nvm_path
    
    # Ensure core utilities are available before loading NVM
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    
    # Load NVM safely (following Shiftsmart's approach)
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    
    # Auto-switch to .nvmrc version if available (following Shiftsmart's emphasis on auto-switching)
    # This is critical for project-specific Node.js versions
    if [[ -f ".nvmrc" ]] && command -v nvm >/dev/null 2>&1; then
        nvm use >/dev/null 2>&1 || true  # Silently fail if version not installed
    fi
fi

# Python/pyenv setup
if [[ -d "$PYENV_ROOT/bin" ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Google Cloud SDK
if [[ -f '/Users/pdfowler/Downloads/google-cloud-sdk/path.zsh.inc' ]]; then
    source '/Users/pdfowler/Downloads/google-cloud-sdk/path.zsh.inc'
fi

# Google Cloud completion (interactive shells only)
if [[ -n "$PS1" ]] && [[ -f '/Users/pdfowler/Downloads/google-cloud-sdk/completion.zsh.inc' ]]; then
    source '/Users/pdfowler/Downloads/google-cloud-sdk/completion.zsh.inc'
fi

# Load bash-completion (works for both bash and zsh)
if [[ -n "$PS1" ]]; then
    # bash-completion is automatically loaded by oh-my-zsh in zsh
    # For bash, we can load it manually if needed
    if [[ -n "$BASH_VERSION" ]] && [[ -f "$(brew --prefix)/etc/bash_completion" ]]; then
        source "$(brew --prefix)/etc/bash_completion"
    fi
fi

# Rust/Cargo binaries
if [[ -d "$HOME/.cargo/bin" ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Development tools (add your custom paths here)
# export PATH="$HOME/bin:$PATH" 