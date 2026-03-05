# Software installation and management functions
# This file contains functions for installing and managing development tools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory containing this file (used to find install-mongodb-tools-direct.sh when sourced from bash)
[[ -n "${BASH_SOURCE[0]:-}" ]] && _SOFTWARE_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Generic command availability check
# Check if a command is installed and available in PATH
check_installed() {
    local command_name="$1"
    if [ -z "$command_name" ]; then
        echo "Usage: check_installed <command_name>" >&2
        return 1
    fi
    command -v "$command_name" >/dev/null 2>&1
}

# Complete system setup function (includes all automated configurations)
setup_system_auto() {
    echo -e "${BLUE}Setting up complete system configuration...${NC}"
    
    # Setup Node.js environment with NVM (following Shiftsmart best practices)
    setup_nodejs_environment_auto
    
    # Install git-sweep
    install_git_sweep
    
    # Install gt (charcoal fork of Graphite CLI) so gt command works when not using LOCAL
    install_gt_charcoal
    
    # Install Powerlevel10k theme for zsh (used by config/shell/zshrc)
    install_powerlevel10k
    
    # Install MongoDB tools (direct download, no Homebrew dependencies)
    install_mongodb_tools
    
    # Configure macOS Finder (only on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        enable_finder_hidden_files
    fi

    # Python setup
    setup_python_environment_auto
    
    echo -e "${GREEN}✅ Complete system setup finished!${NC}"
}

# Powerlevel10k - zsh theme (powerline style with icons, time, duration)
# Requires Nerd Font for icons. Config: config/shell/zsh/.p10k.zsh
install_powerlevel10k() {
    echo -e "${BLUE}Installing Powerlevel10k theme...${NC}"
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local p10k_dir="$zsh_custom/themes/powerlevel10k"
    if [[ -d "$p10k_dir/.git" ]]; then
        echo -e "${GREEN}✓ Powerlevel10k is already installed${NC}"
        return 0
    fi
    if [[ ! -d "$zsh_custom" ]]; then
        echo -e "${YELLOW}⚠ Oh-My-Zsh custom dir not found ($zsh_custom). Install Oh-My-Zsh first, then re-run installer.${NC}"
        return 0
    fi
    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" 2>/dev/null; then
        echo -e "${GREEN}✓ Powerlevel10k installed${NC}"
    else
        echo -e "${YELLOW}⚠ Powerlevel10k clone failed. Install manually: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $p10k_dir${NC}"
    fi
}

# GT (Charcoal/Graphite CLI) - install charcoal fork by default so gt works when not using LOCAL
# Check for the real binary (brew or PATH), not our gt() function, so we always install if missing.
install_gt_charcoal() {
    echo -e "${BLUE}Installing gt (charcoal fork of Graphite CLI)...${NC}"
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Homebrew not found; skip install. Install gt later: brew install danerwilliams/tap/charcoal${NC}"
        return 0
    fi
    local brew_gt
    brew_gt="$(brew --prefix 2>/dev/null)/bin/gt"
    if [[ -x "$brew_gt" ]]; then
        echo -e "${GREEN}✓ gt (charcoal) is already installed${NC}"
        return 0
    fi
    # Charcoal = open-source fork of Graphite CLI (binary is gt)
    if brew install danerwilliams/tap/charcoal; then
        echo -e "${GREEN}✓ gt (charcoal) installed${NC}"
    else
        echo -e "${YELLOW}⚠ gt install failed. Install manually: brew install danerwilliams/tap/charcoal${NC}"
    fi
}

# Git-sweep Management
# These functions handle git-sweep installation and management

# Install git-sweep via global virtual environment
install_git_sweep() {
    echo -e "${BLUE}Installing git-sweep...${NC}"
    
    if check_installed git-sweep; then
        echo -e "${GREEN}✓ git-sweep is already installed${NC}"
        return 0
    fi
    
    # Check if global venv exists, create if not
    local venv_dir="$HOME/.local/venv"
    if [[ ! -d "$venv_dir" ]]; then
        echo -e "${YELLOW}Global virtual environment not found. Creating it first...${NC}"
        # Source aliases.sh to get create_global_venv function
        if [[ -f "$HOME/.config/shell/aliases.sh" ]]; then
            source "$HOME/.config/shell/aliases.sh"
        elif [[ -f "$DOTFILES_DIR/config/shell/aliases.sh" ]]; then
            source "$DOTFILES_DIR/config/shell/aliases.sh"
        fi
        
        if ! create_global_venv; then
            echo -e "${RED}❌ Error: Failed to create global virtual environment${NC}"
            return 1
        fi
    fi
    
    # Install git-sweep in global venv
    echo -e "${YELLOW}Installing git-sweep in global virtual environment...${NC}"
    source "$venv_dir/bin/activate"
    if pip install git-sweep; then
        deactivate
        echo -e "${GREEN}✓ git-sweep installed successfully in global virtual environment${NC}"
        echo -e "${YELLOW}💡 Use 'gvenv' to activate the global venv and access git-sweep${NC}"
        return 0
    else
        deactivate
        echo -e "${RED}❌ Error: Failed to install git-sweep${NC}"
        return 1
    fi
}

# MongoDB Tools Management
# These functions handle MongoDB tools installation and management without Homebrew dependencies

# Check if MongoDB tools are installed
is_mongodb_tools_installed() {
    command -v mongosh >/dev/null 2>&1 && command -v mongodump >/dev/null 2>&1
}

# Get current mongosh version
get_mongosh_version() {
    if check_installed mongosh; then
        mongosh --version 2>/dev/null | head -n1 | sed 's/.*mongosh[[:space:]]*//' | sed 's/[[:space:]].*//' | head -n1
    else
        echo "not-installed"
    fi
}

# Ensure ~/.local/bin is in PATH (needed for MongoDB tools)
ensure_local_bin_in_path() {
    local local_bin="$HOME/.local/bin"
    
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        echo -e "${YELLOW}Adding $local_bin to PATH...${NC}"
        export PATH="$local_bin:$PATH"
        
        # Add to shell profile
        case "$SHELL" in
            */zsh)
                local profile="$HOME/.zshrc"
                ;;
            */bash)
                local profile="$HOME/.bashrc"
                ;;
            *)
                echo -e "${YELLOW}⚠️  Unknown shell: $SHELL${NC}"
                return 1
                ;;
        esac
        
        if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$profile" 2>/dev/null; then
            echo -e "${YELLOW}Adding PATH export to $profile...${NC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$profile"
            echo -e "${GREEN}✓ Added to $profile - restart your shell or run 'source $profile'${NC}"
        else
            echo -e "${GREEN}✓ Already in $profile${NC}"
        fi
    else
        echo -e "${GREEN}✓ $local_bin is already in PATH${NC}"
    fi
}

# Resolve path to install-mongodb-tools-direct.sh (single source of truth for download/install logic).
_get_mongodb_tools_script() {
    if [[ -n "${_SOFTWARE_SH_DIR:-}" && -f "${_SOFTWARE_SH_DIR}/install-mongodb-tools-direct.sh" ]]; then
        echo "${_SOFTWARE_SH_DIR}/install-mongodb-tools-direct.sh"
    elif [[ -n "${DOTFILES_DIR:-}" && -f "${DOTFILES_DIR}/config/shell/install-mongodb-tools-direct.sh" ]]; then
        echo "${DOTFILES_DIR}/config/shell/install-mongodb-tools-direct.sh"
    elif [[ -f "$HOME/.config/shell/install-mongodb-tools-direct.sh" ]]; then
        echo "$HOME/.config/shell/install-mongodb-tools-direct.sh"
    else
        return 1
    fi
}

# Install MongoDB tools via direct download; delegates to install-mongodb-tools-direct.sh.
install_mongodb_tools() {
    if is_mongodb_tools_installed; then
        echo -e "${GREEN}✓ MongoDB tools are already installed${NC}"
        return 0
    fi

    local script
    script=$(_get_mongodb_tools_script) || { echo -e "${RED}❌ Error: install-mongodb-tools-direct.sh not found${NC}" >&2; return 1; }

    echo -e "${BLUE}Installing MongoDB tools (direct download)...${NC}"
    bash "$script"
    return $?
}

# Install mongosh (alias for install_mongodb_tools for backward compatibility)
install_mongosh() {
    install_mongodb_tools
}

# Upgrade MongoDB tools to latest version (runs direct script so reinstall actually runs).
upgrade_mongodb_tools() {
    echo -e "${BLUE}Upgrading MongoDB tools...${NC}"
    
    local script
    script=$(_get_mongodb_tools_script) || { echo -e "${RED}❌ Error: install-mongodb-tools-direct.sh not found${NC}" >&2; return 1; }
    
    if ! is_mongodb_tools_installed; then
        echo -e "${YELLOW}MongoDB tools are not installed. Installing them first...${NC}"
    else
        echo -e "${YELLOW}Reinstalling MongoDB tools to latest version...${NC}"
    fi
    bash "$script"
    return $?
}

# Check and upgrade MongoDB tools on demand
check_upgrade_mongodb_tools() {
    echo -e "${BLUE}Checking MongoDB tools status...${NC}"
    
    if ! is_mongodb_tools_installed; then
        echo -e "${YELLOW}MongoDB tools are not installed.${NC}"
        read -p "Would you like to install them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_mongodb_tools
        else
            echo -e "${YELLOW}Installation cancelled.${NC}"
        fi
        return
    fi
    
    local current_version
    current_version=$(get_mongosh_version)
    
    echo -e "${YELLOW}Current mongosh version: $current_version${NC}"
    echo -e "${YELLOW}MongoDB tools are installed via direct download.${NC}"
    echo -e "${YELLOW}To upgrade, run: upgrade_mongodb_tools${NC}"
}

# Check for brew MongoDB tools conflicts
check_brew_mongodb_conflict() {
    if brew ls --versions mongosh mongodb-database-tools >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Warning: MongoDB tools are installed via Homebrew${NC}"
        echo -e "${YELLOW}   This can cause Node.js dependency conflicts${NC}"
        echo -e "${YELLOW}   Consider uninstalling: brew uninstall mongosh mongodb-database-tools${NC}"
        echo -e "${YELLOW}   Then use: install_mongodb_tools${NC}"
        return 1
    else
        echo -e "${GREEN}✓ No Homebrew MongoDB tools conflicts detected${NC}"
        return 0
    fi
}

# Node.js and NVM Management
# These functions handle Node.js installation and management using NVM (following Shiftsmart best practices)

# Check if NVM is installed
is_nvm_installed() {
    [[ -d "$HOME/.nvm" ]] && [[ -f "$HOME/.nvm/nvm.sh" ]]
}

# Check if Node.js is installed via NVM
is_node_installed_via_nvm() {
    if is_nvm_installed; then
        # Source NVM to check if Node.js is installed
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        command -v node >/dev/null 2>&1 && [[ "$(which node)" == *".nvm"* ]]
    else
        return 1
    fi
}

# Check if Node.js is installed via Homebrew (problematic)
is_node_installed_via_homebrew() {
    command -v node >/dev/null 2>&1 && [[ "$(which node)" == *"homebrew"* ]]
}

# Get current Node.js version
get_node_version() {
    if check_installed node; then
        node --version 2>/dev/null | sed 's/v//'
    else
        echo "not-installed"
    fi
}

# Get current NVM version
get_nvm_version() {
    if is_nvm_installed; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm --version 2>/dev/null | head -n1
    else
        echo "not-installed"
    fi
}

# Install NVM via Homebrew (following Shiftsmart pattern)
install_nvm() {
    echo -e "${BLUE}Installing NVM (Node Version Manager)...${NC}"
    
    if is_nvm_installed; then
        echo -e "${GREEN}✓ NVM is already installed${NC}"
        return 0
    fi
    
    # Check if Homebrew is available
    if ! check_installed brew; then
        echo -e "${RED}❌ Error: Homebrew is required but not found. Please install Homebrew first.${NC}"
        return 1
    fi
    
    # Install NVM via Homebrew (following Shiftsmart's approach)
    echo -e "${YELLOW}Installing NVM via Homebrew...${NC}"
    if brew install nvm; then
        echo -e "${GREEN}✓ NVM installed successfully${NC}"
        
        # Create NVM directory if it doesn't exist
        if [[ ! -d "$HOME/.nvm" ]]; then
            mkdir -p "$HOME/.nvm"
            echo -e "${GREEN}✓ Created NVM directory${NC}"
        fi
        
        # Source NVM for current session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        echo -e "${YELLOW}💡 NVM installed. You may need to restart your shell or run 'source ~/.zshrc'${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install NVM${NC}"
        return 1
    fi
}

# Install Node.js via NVM (recommended version)
install_node_via_nvm() {
    echo -e "${BLUE}Installing Node.js via NVM...${NC}"
    
    # Ensure NVM is installed first
    if ! is_nvm_installed; then
        echo -e "${YELLOW}NVM not found. Installing it first...${NC}"
        if ! install_nvm; then
            echo -e "${RED}❌ Error: Failed to install NVM. Cannot install Node.js.${NC}"
            return 1
        fi
    fi
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Node.js LTS (following Shiftsmart's pattern of using stable versions)
    echo -e "${YELLOW}Installing Node.js LTS via NVM...${NC}"
    if nvm install --lts; then
        echo -e "${GREEN}✓ Node.js LTS installed successfully${NC}"
        
        # Set as default
        nvm alias default lts/*
        echo -e "${GREEN}✓ Node.js LTS set as default${NC}"
        
        # Show version
        local node_version
        node_version=$(get_node_version)
        echo -e "${YELLOW}Installed Node.js version: $node_version${NC}"
        
        ensure_yarn_available
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install Node.js via NVM${NC}"
        return 1
    fi
}

# Ensure yarn is available for the current Node (corepack enable, or npm i -g yarn).
# Call with NVM already sourced so node/npm are on PATH.
ensure_yarn_available() {
    if ! command -v node >/dev/null 2>&1; then
        return 0
    fi
    if command -v yarn >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Yarn is already available${NC}"
        return 0
    fi
    if command -v corepack >/dev/null 2>&1; then
        if corepack enable 2>/dev/null; then
            echo -e "${GREEN}✓ Yarn enabled via corepack${NC}"
            return 0
        fi
    fi
    echo -e "${YELLOW}Enabling yarn via npm install -g yarn...${NC}"
    if npm install -g yarn 2>/dev/null; then
        echo -e "${GREEN}✓ Yarn installed globally${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not enable yarn (run 'corepack enable' or 'npm i -g yarn' with nvm loaded)${NC}"
    fi
}

# Install specific Node.js version via NVM
install_node_version() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo -e "${RED}❌ Usage: install_node_version <version>${NC}"
        echo -e "${YELLOW}Example: install_node_version 22${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Installing Node.js version $version via NVM...${NC}"
    
    # Ensure NVM is installed first
    if ! is_nvm_installed; then
        echo -e "${YELLOW}NVM not found. Installing it first...${NC}"
        if ! install_nvm; then
            echo -e "${RED}❌ Error: Failed to install NVM. Cannot install Node.js.${NC}"
            return 1
        fi
    fi
    
    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install specific version
    echo -e "${YELLOW}Installing Node.js version $version via NVM...${NC}"
    if nvm install "$version"; then
        echo -e "${GREEN}✓ Node.js version $version installed successfully${NC}"
        
        # Use this version
        nvm use "$version"
        echo -e "${GREEN}✓ Switched to Node.js version $version${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install Node.js version $version${NC}"
        return 1
    fi
}

# Check for Homebrew-installed Node.js and warn
check_homebrew_node_conflict() {
    if is_node_installed_via_homebrew; then
        echo -e "${YELLOW}⚠️  Warning: Node.js is installed via Homebrew${NC}"
        echo -e "${YELLOW}   This can cause conflicts with NVM-managed Node.js versions${NC}"
        echo -e "${YELLOW}   Consider uninstalling: brew uninstall node${NC}"
        echo -e "${YELLOW}   Then use NVM for Node.js management instead${NC}"
        return 1
    else
        echo -e "${GREEN}✓ No Homebrew Node.js conflicts detected${NC}"
        return 0
    fi
}

# Setup Node.js environment (following Shiftsmart best practices)
setup_nodejs_environment() {
    echo -e "${BLUE}Setting up Node.js environment with NVM...${NC}"
    
    # Check for conflicts first
    check_homebrew_node_conflict
    
    # Install NVM if not present
    if ! is_nvm_installed; then
        echo -e "${YELLOW}Installing NVM...${NC}"
        if ! install_nvm; then
            echo -e "${RED}❌ Error: Failed to install NVM${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ NVM is already installed${NC}"
    fi
    
    # Install Node.js LTS if not present
    if ! is_node_installed_via_nvm; then
        echo -e "${YELLOW}Installing Node.js LTS via NVM...${NC}"
        if ! install_node_via_nvm; then
            echo -e "${RED}❌ Error: Failed to install Node.js via NVM${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Node.js is already installed via NVM${NC}"
        ensure_yarn_available
    fi
    
    # Show current status
    local node_version
    local nvm_version
    node_version=$(get_node_version)
    nvm_version=$(get_nvm_version)
    
    echo -e "${GREEN}✅ Node.js environment setup complete!${NC}"
    echo -e "${YELLOW}💡 Current versions:${NC}"
    echo "   - Node.js: $node_version"
    echo "   - NVM: $nvm_version"
    echo -e "${YELLOW}💡 You can now use:${NC}"
    echo "   - 'nvm list' to see installed versions"
    echo "   - 'nvm install <version>' to install specific versions"
    echo "   - 'nvm use <version>' to switch versions"
    echo "   - 'nvm current' to see current version"
}

# Auto-setup Node.js environment (non-interactive)
setup_nodejs_environment_auto() {
    echo -e "${BLUE}Automatically setting up Node.js environment with NVM...${NC}"
    
    # Install NVM if not present
    if ! is_nvm_installed; then
        echo -e "${YELLOW}Installing NVM...${NC}"
        if ! install_nvm; then
            echo -e "${RED}❌ Error: Failed to install NVM${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ NVM is already installed${NC}"
    fi
    
    # Install Node.js LTS if not present
    if ! is_node_installed_via_nvm; then
        echo -e "${YELLOW}Installing Node.js LTS via NVM...${NC}"
        if ! install_node_via_nvm; then
            echo -e "${RED}❌ Error: Failed to install Node.js via NVM${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Node.js is already installed via NVM${NC}"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        ensure_yarn_available
    fi
    
    echo -e "${GREEN}✅ Node.js environment setup complete!${NC}"
}

# NX Monorepo Tool Management
# These functions handle Nx installation and management following Shiftsmart best practices

# Check if Nx is installed globally (problematic)
is_nx_installed_globally() {
    command -v nx >/dev/null 2>&1 && [[ "$(which nx)" != *"npx"* ]]
}

# Check if Nx is installed via Homebrew (problematic)
is_nx_installed_via_homebrew() {
    command -v nx >/dev/null 2>&1 && [[ "$(which nx)" == *"homebrew"* ]]
}

# Get current Nx version (from local project or global)
get_nx_version() {
    if check_installed npx; then
        # Try to get version from local project first
        if [[ -f "package.json" ]] && grep -q "nx" package.json; then
            npx nx --version 2>/dev/null | head -n1 | sed 's/.*nx[[:space:]]*//' | sed 's/[[:space:]].*//' | head -n1
        else
            echo "not-in-project"
        fi
    else
        echo "npx-not-available"
    fi
}

# Check for Nx conflicts
check_nx_conflict() {
    if is_nx_installed_via_homebrew; then
        echo -e "${YELLOW}⚠️  Warning: Nx is installed via Homebrew${NC}"
        echo -e "${YELLOW}   This can cause conflicts with project-specific Nx versions${NC}"
        echo -e "${YELLOW}   Consider uninstalling: brew uninstall nx${NC}"
        echo -e "${YELLOW}   Then use 'npx nx' or install Nx per project instead${NC}"
        return 1
    elif is_nx_installed_globally; then
        echo -e "${YELLOW}⚠️  Warning: Nx is installed globally${NC}"
        echo -e "${YELLOW}   This can cause conflicts with project-specific Nx versions${NC}"
        echo -e "${YELLOW}   Consider uninstalling global Nx and use 'npx nx' instead${NC}"
        return 1
    else
        echo -e "${GREEN}✓ No Nx conflicts detected - using npx nx approach${NC}"
        return 0
    fi
}

# Install Nx in a specific project (recommended approach)
install_nx_in_project() {
    local project_dir="${1:-.}"
    
    if [[ ! -d "$project_dir" ]]; then
        echo -e "${RED}❌ Error: Project directory '$project_dir' not found${NC}"
        return 1
    fi
    
    cd "$project_dir"
    
    if [[ ! -f "package.json" ]]; then
        echo -e "${RED}❌ Error: No package.json found in '$project_dir'${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Installing Nx in project: $project_dir${NC}"
    
    # Install Nx as a dev dependency
    if npm install --save-dev nx; then
        echo -e "${GREEN}✓ Nx installed as dev dependency${NC}"
        echo -e "${YELLOW}💡 You can now use 'npx nx' or 'npm run nx' in this project${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install Nx${NC}"
        return 1
    fi
}

# Setup Nx for a new project
setup_nx_project() {
    local project_dir="${1:-.}"
    
    if [[ ! -d "$project_dir" ]]; then
        echo -e "${RED}❌ Error: Project directory '$project_dir' not found${NC}"
        return 1
    fi
    
    cd "$project_dir"
    
    echo -e "${BLUE}Setting up Nx project in: $project_dir${NC}"
    
    # Initialize Nx workspace
    if npx create-nx-workspace@latest . --preset=empty --packageManager=npm --nxCloud=skip; then
        echo -e "${GREEN}✓ Nx workspace initialized${NC}"
        echo -e "${YELLOW}💡 You can now use 'npx nx' commands in this project${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: Failed to initialize Nx workspace${NC}"
        return 1
    fi
}

# macOS Finder settings
enable_finder_hidden_files() {
    echo -e "${BLUE}Configuring macOS Finder to show hidden files...${NC}"
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${YELLOW}⚠️  Warning: This function only works on macOS${NC}"
        return 1
    fi
    
    # Enable hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    
    # Restart Finder to apply changes
    killall Finder
    
    echo -e "${GREEN}✓ Hidden files are now visible in Finder${NC}"
    echo -e "${YELLOW}💡 To hide them again, run: defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder${NC}"
}

# Python setup
setup_python_environment_auto() {
    echo -e "${BLUE}Setting up Python environment...${NC}"
    
    # Install Python if not present
    if ! check_installed uv; then
        echo -e "${YELLOW}Installing uv...${NC}"
        if ! install_uv; then
            echo -e "${RED}❌ Error: Failed to install uv${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ uv is already installed${NC}"
    fi
}

# Install uv
install_uv() {
    echo -e "${BLUE}Installing uv v0.9.2...${NC}"
    
    # Install uv using the official install script
    if curl -LsSf https://astral.sh/uv/0.9.2/install.sh | sh; then
        echo -e "${GREEN}✓ uv v0.9.2 installed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install uv${NC}"
        return 1
    fi
}


# Shell Completion Management
# These functions handle completion setup using bash-completion (works for both bash and zsh)

# Check if bash-completion is installed
is_bash_completion_installed() {
    [[ -d "$(brew --prefix)/etc/bash_completion.d" ]] 2>/dev/null
}

# Setup completions using bash-completion system
setup_completions() {
    echo -e "${BLUE}Setting up shell completions...${NC}"
    
    # Check if bash-completion is available
    if ! is_bash_completion_installed; then
        echo -e "${YELLOW}Installing bash-completion...${NC}"
        if brew install bash-completion; then
            echo -e "${GREEN}✓ bash-completion installed${NC}"
        else
            echo -e "${RED}❌ Failed to install bash-completion${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ bash-completion already installed${NC}"
    fi
    
    # Setup kubectl completion
    setup_kubectl_completion
    
    # Verify other tool completions
    verify_completions
    
    echo -e "${GREEN}✓ Shell completions setup complete${NC}"
}

# Setup kubectl completion using bash-completion
setup_kubectl_completion() {
    if check_installed kubectl; then
        echo -e "${YELLOW}Setting up kubectl completion...${NC}"
        
        local completion_file="$(brew --prefix)/etc/bash_completion.d/kubectl"
        
        # Check if kubectl completion is already set up
        if [[ -f "$completion_file" ]]; then
            echo -e "${GREEN}✓ kubectl completion already configured${NC}"
        else
            # Generate kubectl completion for bash-completion
            if kubectl completion bash > "$completion_file" 2>/dev/null; then
                echo -e "${GREEN}✓ kubectl completion added to bash-completion${NC}"
            else
                echo -e "${YELLOW}⚠️  Failed to generate kubectl completion${NC}"
                rm -f "$completion_file"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  kubectl not found, skipping completion setup${NC}"
    fi
}

# Verify that completions are working
verify_completions() {
    echo -e "${YELLOW}Verifying completions...${NC}"
    
    local bash_completion_dir="$(brew --prefix)/etc/bash_completion.d"
    local completion_count=0
    
    # Count available completions
    if [[ -d "$bash_completion_dir" ]]; then
        completion_count=$(ls -1 "$bash_completion_dir" 2>/dev/null | wc -l)
        echo -e "${GREEN}✓ Found $completion_count completion files in bash-completion${NC}"
        
        # List some key completions
        echo -e "${BLUE}Available completions:${NC}"
        ls -1 "$bash_completion_dir" | head -10 | sed 's/^/  - /'
        if [[ $completion_count -gt 10 ]]; then
            echo -e "  ... and $((completion_count - 10)) more"
        fi
    else
        echo -e "${YELLOW}⚠️  bash-completion directory not found${NC}"
    fi
}

# Add completion for a tool that supports bash-completion
add_completion() {
    local tool_name="$1"
    local completion_command="$2"
    
    if [[ -z "$tool_name" || -z "$completion_command" ]]; then
        echo -e "${RED}❌ Usage: add_completion <tool_name> <completion_command>${NC}"
        echo -e "${YELLOW}Example: add_completion kubectl 'kubectl completion bash'${NC}"
        return 1
    fi
    
    if check_installed "$tool_name"; then
        echo -e "${YELLOW}Adding $tool_name completion...${NC}"
        
        local completion_file="$(brew --prefix)/etc/bash_completion.d/$tool_name"
        
        if eval "$completion_command" > "$completion_file" 2>/dev/null; then
            echo -e "${GREEN}✓ $tool_name completion added to bash-completion${NC}"
        else
            echo -e "${YELLOW}⚠️  Failed to generate $tool_name completion${NC}"
            rm -f "$completion_file"
        fi
    else
        echo -e "${YELLOW}⚠️  $tool_name not found, skipping completion setup${NC}"
    fi
}

# Reload completions (useful after installing new tools)
reload_completions() {
    echo -e "${BLUE}Reloading shell completions...${NC}"
    
    # For bash-completion, we need to reload the bash-completion system
    if [[ -n "$ZSH_VERSION" ]]; then
        # In zsh, bash-completion is usually loaded via oh-my-zsh or manually
        echo -e "${GREEN}✓ Completions will be available in new shell sessions${NC}"
        echo -e "${YELLOW}💡 Run 'exec zsh' to reload completions in current session${NC}"
    elif [[ -n "$BASH_VERSION" ]]; then
        # In bash, we can reload bash-completion
        if [[ -f "$(brew --prefix)/etc/bash_completion" ]]; then
            source "$(brew --prefix)/etc/bash_completion"
            echo -e "${GREEN}✓ bash-completion reloaded${NC}"
        else
            echo -e "${YELLOW}⚠️  bash-completion not found${NC}"
        fi
    fi
}

# Convenience aliases for software management
alias git-sweep-install='install_git_sweep'
alias mongodb-tools-install='install_mongodb_tools'
alias mongodb-tools-upgrade='upgrade_mongodb_tools'
alias mongodb-tools-check='check_upgrade_mongodb_tools'
alias mongosh-install='install_mongosh'  # Backward compatibility
alias mongosh-upgrade='upgrade_mongodb_tools'  # Backward compatibility
alias mongosh-check='check_upgrade_mongodb_tools'  # Backward compatibility
alias show-hidden-files='enable_finder_hidden_files'
alias system-setup='setup_system_auto'
alias completions-setup='setup_completions'
alias completions-reload='reload_completions'

# Node.js and NVM management aliases (following Shiftsmart best practices)
alias node-setup='setup_nodejs_environment'
alias nvm-install='install_nvm'
alias node-install='install_node_via_nvm'
alias node-install-version='install_node_version'
alias node-check-conflict='check_homebrew_node_conflict'

# Nx management aliases (following Shiftsmart best practices)
alias nx-check-conflict='check_nx_conflict'
alias nx-install-project='install_nx_in_project'
alias nx-setup-project='setup_nx_project'
