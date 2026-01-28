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

# Git helper functions for automated contexts
git_rebase_no_edit() {
    # Use non-interactive rebase to avoid editor hanging
    EDITOR="cat" GIT_EDITOR="cat" git rebase "$@"
}

git_commit_no_edit() {
    # Use non-interactive commit to avoid editor hanging
    EDITOR="cat" GIT_EDITOR="cat" git commit "$@"
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
  [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: cd() called with args: $@"
  [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Current PATH: $PATH"
  [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Current PWD: $PWD"
  
  if [[ "$1" == @* ]]; then
    [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Matched @ pattern: $1"
    case "$1" in
      @dev)
        local path="$HOME/Development"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @dev case - path: $path"
        ;;
      @dev/*)
        local sub="${1#@dev/}"
        local path="$HOME/Development/$sub"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @dev/* case - sub: $sub, path: $path"
        ;;
      @dotfiles)
        local path="$SHIFTSMART_ROOT/dotfiles"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @dotfiles case - path: $path"
        ;;
      @shiftsmart)
        local path="$SHIFTSMART_ROOT"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @shiftsmart case - path: $path"
        ;;
      @ssm/*)
        local sub="${1#@ssm/}"
        local path="$SHIFTSMART_ROOT/services/ssm/packages/$sub"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @ssm/* case - sub: $sub, path: $path"
        ;;
      @monorepo/packages/*)
        local sub="${1#@monorepo/packages/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @monorepo/packages/* case - sub: $sub, path: $path"
        ;;
      @monorepo/applications/*)
        local sub="${1#@monorepo/applications/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/applications/$sub"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @monorepo/applications/* case - sub: $sub, path: $path"
        ;;
      @monorepo/*)
        local sub="${1#@monorepo/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @monorepo/* case - sub: $sub, path: $path"
        ;;
      @*)
        local dir="${1#@}"
        local path="$SHIFTSMART_ROOT/services/$dir"
        [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: @* case - dir: $dir, path: $path"
        ;;
    esac
    if [[ -d "$path" ]]; then
      [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Directory exists, changing to: $path"
      builtin cd "$path"
      # if [[ -n "$chpwd_functions" ]]; then
      #   for chpwd_hook in "${chpwd_functions[@]}"; do
      #     "$chpwd_hook"
      #   done
      # fi
      [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Changed to: $(pwd)"
    else
      [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: Directory not found: $path"
      return 1
    fi
    return
  fi
  [[ -n "${DEBUG_CD:-}" ]] && echo "DEBUG: No @ pattern match, using builtin cd with: $@"
  builtin cd "$@"
  # if [[ -n "$chpwd_functions" ]]; then
  #   for chpwd_hook in "${chpwd_functions[@]}"; do
  #     "$chpwd_hook"
  #   done
  # fi
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
    
    # Ensure core utilities are always available
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    
    # Check if the hook exists
    if [[ -n "${chpwd_functions:-}" ]] && echo "${chpwd_functions[@]}" | grep -q "_zsh_nvm_auto_use"; then
        echo "Found NVM hook, creating PATH-safe wrapper..."
        
        # Create a wrapper function that ensures PATH is correct
        _zsh_nvm_auto_use_wrapper() {
            # Ensure core utilities are available before any NVM operations
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
    
    # Also fix NVM functions that might be causing issues
    if declare -f _zsh_nvm_nvm >/dev/null 2>&1; then
        echo "Creating PATH-safe NVM function wrapper..."
        
        # Store the original function
        eval "_zsh_nvm_nvm_original() { $(declare -f _zsh_nvm_nvm | sed '1,2d;$d') }"
        
        # Create a wrapper that ensures PATH is correct
        _zsh_nvm_nvm() {
            # Ensure core utilities are available
            export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
            
            # Call the original function
            _zsh_nvm_nvm_original "$@"
        }
        
        echo "✓ NVM function PATH issues fixed"
    fi
}

# Fix NVM nounset issue - handles unset NVM_NO_USE variable
fix_nvm_nounset() {
    echo "Fixing NVM nounset issue..."
    
    # Set NVM_NO_USE to prevent conflicts with zsh-nvm plugin
    export NVM_NO_USE="${NVM_NO_USE:-false}"
    
    echo "✓ NVM nounset issue fixed - NVM_NO_USE is now set"
}

# Fix NVM PATH corruption - immediate fix for "command not found" errors
fix_nvm_path_corruption() {
    echo "Fixing NVM PATH corruption..."
    
    # Restore essential system paths that NVM might have removed
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    
    # Clean up any duplicate or problematic NVM paths
    export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
    
    # Ensure NVM paths are properly appended (not replacing system paths)
    if [[ -n "${NVM_BIN:-}" ]] && [[ -d "$NVM_BIN" ]]; then
        export PATH="$PATH:$NVM_BIN"
    fi
    
    echo "✓ NVM PATH corruption fixed"
    echo "Current PATH: $PATH"
}

# Comprehensive NVM fix that addresses both PATH and nounset issues
fix_nvm_comprehensive() {
    echo "Applying comprehensive NVM fixes..."
    fix_nvm_path_corruption
    fix_nvm_hook_path
    fix_nvm_nounset
    echo "✓ All NVM issues fixed"
}

# Fix aggressive Node.js takeovers from brew dependencies (like mongosh)
fix_brew_node_takeover() {
    echo "Fixing aggressive Node.js takeover from brew dependencies..."
    
    # Ensure NVM-managed Node takes precedence over brew Node
    if [[ -n "${NVM_BIN:-}" ]] && [[ -d "$NVM_BIN" ]]; then
        # Remove any brew node paths from PATH
        export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/opt/homebrew.*node" | tr '\n' ':' | sed 's/:$//')
        
        # Prepend NVM bin to PATH to ensure it takes precedence
        export PATH="$NVM_BIN:$PATH"
        
        echo "✓ NVM-managed Node.js now takes precedence over brew Node"
        echo "Current node: $(which node)"
        echo "Node version: $(node --version)"
    else
        echo "⚠️  NVM_BIN not found. Make sure NVM is properly loaded."
    fi
}

# Check for brew Node conflicts
check_brew_node_conflict() {
    echo "Checking for brew Node.js conflicts..."
    
    local brew_node_path=$(brew --prefix node 2>/dev/null || echo "")
    local current_node=$(which node)
    
    if [[ -n "$brew_node_path" ]] && [[ "$current_node" == *"$brew_node_path"* ]]; then
        echo "🚨 CONFLICT: Using brew Node.js instead of NVM-managed Node"
        echo "  Brew Node path: $current_node"
        echo "  Run 'fix_brew_node_takeover' to fix this"
        return 1
    else
        echo "✅ No brew Node.js conflict detected"
        echo "  Current Node: $current_node"
        return 0
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

# Google Auth Helpers
alias gauth='gcloud auth login && gcloud auth application-default login'

# Quick alias to activate global venv
alias gvenv='activate_global_venv'

# Quick alias to deactivate global venv  
alias gdeactivate='deactivate_global_venv'

# Python aliases
alias pip='pip3'

# MongoDB tools management (references software.sh functions)
alias mongo-tools-install='install_mongodb_tools'
alias mongo-tools-upgrade='upgrade_mongodb_tools'
alias mongo-tools-check='check_upgrade_mongodb_tools'
alias mongo-tools-clean='brew uninstall mongosh mongodb-database-tools 2>/dev/null || echo "No brew MongoDB tools to remove"'
alias mongo-tools-conflict='check_brew_mongodb_conflict'

# NX alias - uses local nx version when available, falls back to npx (Shiftsmart best practice)
alias nx='npx nx'

# Nx management aliases (references software.sh functions)
alias nx-check-conflict='check_nx_conflict'
alias nx-install-project='install_nx_in_project'
alias nx-setup-project='setup_nx_project'
alias nx-clean-brew='brew uninstall nx 2>/dev/null || echo "No brew nx to remove"'

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

# Node.js and NVM Management Aliases (following Shiftsmart best practices)
# These aliases provide convenient access to Node.js management functions

# Quick Node.js version management
alias node-version='node --version'
alias npm-version='npm --version'
alias nvm-version='nvm --version'

# NVM convenience aliases
alias nvm-list='nvm list'
alias nvm-current='nvm current'
alias nvm-use='nvm use'
alias nvm-install-lts='nvm install --lts'
alias nvm-install-node='nvm install node'

# Node.js project management (following Shiftsmart patterns)
alias node-use='nvm use'  # Use .nvmrc version
alias node-install-rc='nvm install'  # Install .nvmrc version

# Quick setup aliases (these call the functions from software.sh)
alias node-setup='setup_nodejs_environment'
alias node-check-conflict='check_homebrew_node_conflict'

# NVM fix aliases
alias fix-nvm='fix_nvm_comprehensive'
alias fix-nvm-path='fix_nvm_hook_path'
alias fix-nvm-nounset='fix_nvm_nounset'
alias fix-nvm-corruption='fix_nvm_path_corruption'
alias fix-brew-node='fix_brew_node_takeover'
alias check-brew-node='check_brew_node_conflict'

# Development workflow aliases (inspired by Shiftsmart's approach)
alias node-dev='nvm use && npm run dev'
alias node-build='nvm use && npm run build'
alias node-test='nvm use && npm test'
alias node-install-deps='nvm use && npm install'

# Package manager aliases (use project-specific versions)
alias pnpm-dev='nvm use && pnpm dev'
alias pnpm-build='nvm use && pnpm build'
alias pnpm-test='nvm use && pnpm test'
alias pnpm-install='nvm use && pnpm install'

alias yarn-dev='nvm use && yarn dev'
alias yarn-build='nvm use && yarn build'
alias yarn-test='nvm use && yarn test'
alias yarn-install='nvm use && yarn install'

# Quick project setup (following Shiftsmart's monorepo patterns)
setup_node_project() {
    echo "Setting up Node.js project with NVM..."
    
    # Check if .nvmrc exists
    if [[ -f ".nvmrc" ]]; then
        echo "Found .nvmrc file, installing and using specified Node.js version..."
        nvm install
        nvm use
    else
        echo "No .nvmrc file found. Using current Node.js version..."
        echo "Current Node.js version: $(node --version)"
    fi
    
    # Install dependencies if package.json exists
    if [[ -f "package.json" ]]; then
        echo "Installing dependencies..."
        if [[ -f "pnpm-lock.yaml" ]]; then
            pnpm install
        elif [[ -f "yarn.lock" ]]; then
            yarn install
        else
            npm install
        fi
    fi
    
    echo "✓ Node.js project setup complete!"
}

alias node-project-setup='setup_node_project'

# Git branch cleanup aliases
alias cleanup-branches='$HOME/.config/shell/cleanup-merged-branches.sh'
alias cleanup-branches-list='$HOME/.config/shell/cleanup-merged-branches.sh --list'
alias cleanup-branches-dry='$HOME/.config/shell/cleanup-merged-branches.sh --dry-run'
alias cleanup-branches-closed='$HOME/.config/shell/cleanup-merged-branches.sh --closed'
alias cleanup-branches-all='$HOME/.config/shell/cleanup-merged-branches.sh --closed --list'

# GT (Graphite/Charcoal CLI) Source Routing Helpers
# These functions support routing to different gt command sources based on GT_SOURCE env var

# Get the path to the local charcoal binary
# Checks common locations for built binaries in a Node.js monorepo structure
_gt_get_local_binary() {
    local charcoal_dir="$HOME/Development/charcoal"
    local binary_path=""
    
    # Check common binary locations (in order of preference)
    # Primary location: compiled binary from charcoal repo structure
    if [[ -f "$charcoal_dir/apps/cli/dist/src/index.js" ]]; then
        binary_path="$charcoal_dir/apps/cli/dist/src/index.js"
    elif [[ -f "$charcoal_dir/apps/cli/dist/cli.js" ]]; then
        binary_path="$charcoal_dir/apps/cli/dist/cli.js"
    elif [[ -f "$charcoal_dir/dist/cli.js" ]]; then
        binary_path="$charcoal_dir/dist/cli.js"
    elif [[ -f "$charcoal_dir/node_modules/.bin/gt" ]]; then
        binary_path="$charcoal_dir/node_modules/.bin/gt"
    elif [[ -f "$charcoal_dir/apps/cli/node_modules/.bin/gt" ]]; then
        binary_path="$charcoal_dir/apps/cli/node_modules/.bin/gt"
    fi
    
    echo "$binary_path"
}

# Check if local charcoal repo exists and is built
# Returns 0 if ready to use, 1 otherwise
_gt_check_local() {
    local charcoal_dir="$HOME/Development/charcoal"
    
    # Check if repo exists
    if [[ ! -d "$charcoal_dir" ]]; then
        return 1
    fi
    
    # Check if binary exists
    local binary_path=$(_gt_get_local_binary)
    if [[ -z "$binary_path" ]] || [[ ! -f "$binary_path" ]]; then
        return 1
    fi
    
    return 0
}

# Build local charcoal instance if needed
# Attempts to build using common package managers (yarn, pnpm, npm)
_gt_build_local() {
    local charcoal_dir="$HOME/Development/charcoal"
    
    if [[ ! -d "$charcoal_dir" ]]; then
        echo "Warning: Local charcoal repo not found at $charcoal_dir" >&2
        return 1
    fi
    
    # Check if already built
    if _gt_check_local; then
        return 0
    fi
    
    echo "Building local charcoal instance..." >&2
    
    # Try to build with available package manager
    if command -v yarn >/dev/null 2>&1 && [[ -f "$charcoal_dir/yarn.lock" ]]; then
        (cd "$charcoal_dir" && yarn build) || return 1
    elif command -v pnpm >/dev/null 2>&1 && [[ -f "$charcoal_dir/pnpm-lock.yaml" ]]; then
        (cd "$charcoal_dir" && pnpm build) || return 1
    elif command -v npm >/dev/null 2>&1 && [[ -f "$charcoal_dir/package.json" ]]; then
        (cd "$charcoal_dir" && npm run build) || return 1
    else
        echo "Warning: No suitable package manager found to build charcoal" >&2
        return 1
    fi
    
    # Verify build succeeded
    if _gt_check_local; then
        return 0
    else
        echo "Warning: Build completed but binary not found" >&2
        return 1
    fi
}

# Graphite stack sync function (replaces missing functionality in Charcoal)
# Enhanced with GT_SOURCE routing support
# 
# GT_SOURCE environment variable controls which version to use:
#   "FORK"    - Use GitHub fork via Homebrew tap (requires tap setup)
#   "LOCAL"   - Use local development instance from ~/Development/charcoal (auto-builds if needed)
#   "CHARCOAL" or unset/null - Use default Charcoal installation
#
# Falls back to default with warning if selected source is unavailable
gt() {
    # Handle special gt stack sync command (always uses default gt)
    if [[ "$1" == "stack" && "$2" == "sync" ]]; then
        # Run the post-squash-merge cleanup script
        "$HOME/Development/dotfiles/squash-merge-restack/restack.sh" "${@:3}"
        return
    fi
    
    # Determine which gt source to use based on GT_SOURCE env var
    local gt_source="${GT_SOURCE:-CHARCOAL}"
    local use_local=false
    local use_fork=false
    local fallback=false
    
    case "$gt_source" in
        LOCAL)
            if _gt_check_local || _gt_build_local; then
                use_local=true
            else
                echo "Warning: GT_SOURCE=LOCAL but local charcoal not available, falling back to default" >&2
                fallback=true
            fi
            ;;
        FORK)
            if command -v gt >/dev/null 2>&1; then
                use_fork=true
            else
                echo "Warning: GT_SOURCE=FORK but gt command not found, falling back to default" >&2
                fallback=true
            fi
            ;;
        CHARCOAL|"")
            # Use default
            ;;
        *)
            echo "Warning: Invalid GT_SOURCE='$gt_source', falling back to default. Valid values: FORK, LOCAL, CHARCOAL" >&2
            fallback=true
            ;;
    esac
    
    # Execute appropriate gt command
    if [[ "$use_local" == true ]]; then
        local binary_path=$(_gt_get_local_binary)
        if [[ -n "$binary_path" ]]; then
            # Execute the binary - use node for .js files, direct execution for others
            if [[ "$binary_path" == *.js ]]; then
                node "$binary_path" "$@"
            else
                "$binary_path" "$@"
            fi
        else
            echo "Error: Local binary path not found" >&2
            return 1
        fi
    elif [[ "$use_fork" == true ]] || [[ "$fallback" == false ]]; then
        # Use default gt command (either FORK mode or CHARCOAL/default mode)
        command gt "$@"
    else
        # Fallback case: try default anyway
        command gt "$@"
    fi
}

# Network diagnostics
network-diagnostics() {
    local script_path=""
    
    # Try multiple possible locations
    if [[ -f "$HOME/.config/shell/network-diagnostics.sh" ]]; then
        script_path="$HOME/.config/shell/network-diagnostics.sh"
    elif [[ -n "$DOTFILES_DIR" && -f "$DOTFILES_DIR/config/shell/network-diagnostics.sh" ]]; then
        script_path="$DOTFILES_DIR/config/shell/network-diagnostics.sh"
    elif [[ -f "$HOME/Development/dotfiles/config/shell/network-diagnostics.sh" ]]; then
        script_path="$HOME/Development/dotfiles/config/shell/network-diagnostics.sh"
    elif [[ -f "./config/shell/network-diagnostics.sh" ]]; then
        script_path="./config/shell/network-diagnostics.sh"
    else
        echo "Network diagnostics script not found"
        echo "Searched in:"
        echo "  - $HOME/.config/shell/network-diagnostics.sh"
        [[ -n "$DOTFILES_DIR" ]] && echo "  - $DOTFILES_DIR/config/shell/network-diagnostics.sh"
        echo "  - $HOME/Development/dotfiles/config/shell/network-diagnostics.sh"
        return 1
    fi
    
    "$script_path" "$@"
}
alias network-check='network-diagnostics'
alias check-dean='network-diagnostics dean 192.168.13.105'

