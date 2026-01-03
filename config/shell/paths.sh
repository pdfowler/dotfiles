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
# Use timeout protection to prevent hanging when GitHub/network is down
if [[ -f '/opt/homebrew/bin/brew' ]]; then
    [[ -n "$DEBUG_SHELL_INIT" ]] && echo "[paths.sh] Setting up Homebrew"
    
    # Clean up any stuck brew shellenv processes from previous sessions
    STUCK_PROCESSES=$(pgrep -f "[b]rew.*shellenv" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$STUCK_PROCESSES" -gt 0 ]]; then
        [[ -n "$DEBUG_SHELL_INIT" ]] && echo "[paths.sh] Cleaning up $STUCK_PROCESSES stuck brew shellenv process(es)"
        pkill -f "brew.*shellenv" 2>/dev/null || true
    fi
    
    # Try brew shellenv with 2-second timeout to prevent hanging
    BREW_ENV=""
    (
        BREW_ENV=$(/opt/homebrew/bin/brew shellenv 2>/dev/null)
        echo "$BREW_ENV" > /tmp/brew_shellenv_output.$$
    ) &
    BREW_PID=$!
    
    # Wait max 2 seconds
    for i in {1..20}; do
        if ! kill -0 $BREW_PID 2>/dev/null; then
            if [[ -f "/tmp/brew_shellenv_output.$$" ]]; then
                BREW_ENV=$(cat "/tmp/brew_shellenv_output.$$" 2>/dev/null)
                rm -f "/tmp/brew_shellenv_output.$$"
            fi
            break
        fi
        sleep 0.1
    done
    
    # If still running, kill it and use manual paths
    if kill -0 $BREW_PID 2>/dev/null; then
        [[ -n "$DEBUG_SHELL_INIT" ]] && echo "[paths.sh] brew shellenv timed out, using manual paths"
        kill $BREW_PID 2>/dev/null
        wait $BREW_PID 2>/dev/null
        rm -f "/tmp/brew_shellenv_output.$$"
        BREW_ENV=""
    fi
    
    # Use brew shellenv output if available, otherwise use manual paths
    if [[ -n "$BREW_ENV" ]] && ! echo "$BREW_ENV" | grep -q "Error\|error\|fatal"; then
        eval "$BREW_ENV"
        [[ -n "$DEBUG_SHELL_INIT" ]] && echo "[paths.sh] Homebrew shellenv loaded successfully"
    else
        # Fallback to manual paths when brew shellenv fails or times out
        [[ -n "$DEBUG_SHELL_INIT" ]] && echo "[paths.sh] Using manual Homebrew paths (brew shellenv unavailable)"
        export HOMEBREW_PREFIX="/opt/homebrew"
        export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
        export HOMEBREW_REPOSITORY="/opt/homebrew"
        export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}"
        export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
        export INFOPATH="/opt/homebrew/share/info${INFOPATH+:$INFOPATH}:"
    fi
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
    
    # Auto-fix NVM PATH corruption issues on startup
    # This prevents "command not found: tr/tail/head/sed" errors
    auto_fix_nvm_path() {
        # Check if core utilities are missing
        local missing_utils=()
        for util in tr tail head sed; do
            if ! command -v "$util" >/dev/null 2>&1; then
                missing_utils+=("$util")
            fi
        done
        
        if [[ ${#missing_utils[@]} -gt 0 ]]; then
            # Restore essential system paths that NVM might have removed
            export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
            
            # Clean up any duplicate or problematic NVM paths
            export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
            
            # Ensure NVM paths are properly appended (not replacing system paths)
            if [[ -n "${NVM_BIN:-}" ]] && [[ -d "$NVM_BIN" ]]; then
                export PATH="$PATH:$NVM_BIN"
            fi
        fi
    }
    
    # Run the auto-fix
    auto_fix_nvm_path
fi

# Python/pyenv setup
# Check if pyenv is available (either via Homebrew or in PYENV_ROOT/bin)
if command -v pyenv >/dev/null 2>&1; then
    # pyenv is already in PATH (e.g., via Homebrew), just initialize it
    eval "$(pyenv init -)" 2>/dev/null || true
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
elif [[ -d "$PYENV_ROOT/bin" ]] && [[ -f "$PYENV_ROOT/bin/pyenv" ]]; then
    # pyenv is in PYENV_ROOT/bin but not in PATH, add it and initialize
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
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