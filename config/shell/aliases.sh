# Cross-shell compatible aliases and functions
# Works in both bash and zsh
# 
# To enable debug output for the custom cd() function, set:
# export DEBUG_CD=1

# Basic aliases
alias ll="ls -la" # long list
alias la="ls -A"  # list all except . and ..
alias lc="ls -CF"  # list in columns
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Editor shortcuts
alias v="$EDITOR"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"
alias root="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
alias ws="cd \$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

settings() {
  case "$SHELL" in
    */zsh)
      $EDITOR ~/.zshrc
      ;;
    */bash)
      $EDITOR ~/.bashrc
      ;;
    *)
      echo "Unknown shell: $SHELL"
      ;;
  esac
}

# Utility functions (cross-shell compatible)
update() {
    case "$SHELL" in
        */zsh)
            echo "Reloading zsh configuration..."
            source ~/.zshenv
            source ~/.zshrc
            ;;
        */bash)
            echo "Reloading bash configuration..."
            source ~/.bashrc
            ;;
        *)
            echo "Unknown shell: $SHELL"
            ;;
    esac
}

# Aliases for Shiftsmart Repos
custom_cd() {
  # Only show debug output if DEBUG_CD is set
  [[ -n "$DEBUG_CD" ]] && echo "DEBUG: cd() called with args: $@"
  [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Current PATH: $PATH"
  [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Current PWD: $PWD"
  
  if [[ "$1" == @* ]]; then
    [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Matched @ pattern: $1"
    case "$1" in
      @dev)
        local path="$HOME/Development"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @dev case - path: $path"
        ;;
      @dev/*)
        local sub="${1#@dev/}"
        local path="$HOME/Development/$sub"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @dev/* case - sub: $sub, path: $path"
        ;;
      @dotfiles)
        local path="$SHIFTSMART_ROOT/dotfiles"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @dotfiles case - path: $path"
        ;;
      @shiftsmart)
        local path="$SHIFTSMART_ROOT"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @shiftsmart case - path: $path"
        ;;
      @ssm/*)
        local sub="${1#@ssm/}"
        local path="$SHIFTSMART_ROOT/services/ssm/packages/$sub"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @ssm/* case - sub: $sub, path: $path"
        ;;
      @monorepo/packages/*)
        local sub="${1#@monorepo/packages/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @monorepo/packages/* case - sub: $sub, path: $path"
        ;;
      @monorepo/applications/*)
        local sub="${1#@monorepo/applications/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/applications/$sub"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @monorepo/applications/* case - sub: $sub, path: $path"
        ;;
      @monorepo/*)
        local sub="${1#@monorepo/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @monorepo/* case - sub: $sub, path: $path"
        ;;
      @*)
        local dir="${1#@}"
        local path="$SHIFTSMART_ROOT/services/$dir"
        [[ -n "$DEBUG_CD" ]] && echo "DEBUG: @* case - dir: $dir, path: $path"
        ;;
    esac
    if [[ -d "$path" ]]; then
      [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Directory exists, changing to: $path"
      builtin cd "$path"
      [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Changed to: $(pwd)"
    else
      [[ -n "$DEBUG_CD" ]] && echo "DEBUG: Directory not found: $path"
      return 1
    fi
    return
  fi
  [[ -n "$DEBUG_CD" ]] && echo "DEBUG: No @ pattern match, using builtin cd with: $@"
  builtin cd "$@"
}

# Find and kill process by name
killall_grep() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
} 

# Find and kill process by port
killall_port() {
    lsof -i :$1 | awk 'NR>1 {print $2}' | xargs kill -9
}

# Debug helper functions
debug_cd_on() {
    export DEBUG_CD=1
    echo "Debug mode enabled for cd() function. Set DEBUG_CD=0 to disable."
}

debug_cd_off() {
    unset DEBUG_CD
    echo "Debug mode disabled for cd() function."
}

# Test the custom cd function
test_cd() {
    echo "Testing custom cd function..."
    echo "Current directory: $(pwd)"
    echo "Testing @monorepo alias..."
    custom_cd @monorepo
    echo "New directory: $(pwd)"
    echo "Test complete!"
}

# Alias to use the custom cd function
alias cd='custom_cd'

# Fix NVM PATH issues
fix_nvm_path() {
    echo "Fixing NVM PATH issues..."
    
    # Unload NVM if it's loaded
    if command -v nvm >/dev/null 2>&1; then
        echo "Unloading NVM..."
        nvm unload
    fi
    
    # Ensure core utilities are available first
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    
    # Now remove NVM-related paths from PATH (using the now-available commands)
    echo "Cleaning PATH of NVM entries..."
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.nvm" | tr '\n' ':' | sed 's/:$//')
    
    # Unset NVM environment variables
    unset NVM_BIN NVM_INC NVM_DIR NVM_RC_VERSION
    
    echo "NVM PATH issues fixed. You can now use the cd aliases without errors."
    echo "To reload your shell configuration, run: source ~/.zshenv"
}

# Fix NVM hook PATH issues while keeping auto-switching
fix_nvm_hook_path() {
    echo "Fixing NVM hook PATH issues..."
    
    # Check if the hook exists
    if [[ -n "$chpwd_functions" ]] && echo "$chpwd_functions" | grep -q "_zsh_nvm_auto_use"; then
        echo "Found NVM hook, creating PATH-safe wrapper..."
        
        # Create a wrapper function that ensures PATH is correct
        _zsh_nvm_auto_use_wrapper() {
            # Ensure core utilities are available
            export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
            
            # Now call the original function
            _zsh_nvm_auto_use "$@"
        }
        
        # Replace the original hook with our wrapper
        chpwd_functions=("${chpwd_functions[@]/_zsh_nvm_auto_use/_zsh_nvm_auto_use_wrapper}")
        
        echo "✓ NVM hook PATH issues fixed while keeping auto-switching"
    else
        echo "No NVM hook found to fix"
    fi
}

# Global Python Virtual Environment Management
# These functions help manage a global virtual environment for tools like uv/uvx

# Create global virtual environment if it doesn't exist
create_global_venv() {
    local venv_dir="$HOME/.local/venv"
    
    if [[ ! -d "$venv_dir" ]]; then
        echo "Creating global virtual environment at $venv_dir..."
        python3 -m venv "$venv_dir"
        echo "✓ Global virtual environment created"
        
        # Activate and install common tools
        echo "Installing common Python tools..."
        source "$venv_dir/bin/activate"
        pip install --upgrade pip
        pip install uv
        echo "✓ Installed uv (includes uvx) and upgraded pip"
        deactivate
    else
        echo "Global virtual environment already exists at $venv_dir"
    fi
}

# Activate global virtual environment
activate_global_venv() {
    local venv_dir="$HOME/.local/venv"
    
    if [[ ! -d "$venv_dir" ]]; then
        echo "Global virtual environment not found. Creating it first..."
        create_global_venv
    fi
    
    echo "Activating global virtual environment..."
    source "$venv_dir/bin/activate"
    echo "✓ Global virtual environment activated"
    echo "You can now use uv/uvx and other Python tools"
}

# Deactivate global virtual environment
deactivate_global_venv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        deactivate
        echo "✓ Global virtual environment deactivated"
    else
        echo "No virtual environment is currently active"
    fi
}

# Quick alias to activate global venv
alias gvenv='activate_global_venv'

# Quick alias to deactivate global venv  
alias gdeactivate='deactivate_global_venv'

# Python aliases
alias pip='pip3'

# NX alias - uses local nx version when available, falls back to npx
alias nx='npx nx'

# Install uv (includes uvx) in global venv (convenience function)
install_uv() {
    local venv_dir="$HOME/.local/venv"
    
    if [[ ! -d "$venv_dir" ]]; then
        echo "Creating global virtual environment first..."
        create_global_venv
    else
    echo "Installing/updating uv (includes uvx) in global virtual environment..."
    source "$venv_dir/bin/activate"
    pip install --upgrade uv
    deactivate
    echo "✓ uv (includes uvx) installed/updated"
    fi
}

