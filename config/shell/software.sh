# Software installation and management functions
# This file contains functions for installing and managing development tools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Rust/Cargo and git-stack Management
# These functions handle Rust toolchain and git-stack installation/management

# Check if Rust/Cargo is installed
is_rust_installed() {
    command -v cargo >/dev/null 2>&1 && command -v rustc >/dev/null 2>&1
}

# Check if git-stack is installed
is_git_stack_installed() {
    command -v git-stack >/dev/null 2>&1
}

# Get current git-stack version
get_git_stack_version() {
    if is_git_stack_installed; then
        # Try to get version from git-stack --version output
        local version_output
        version_output=$(git-stack --version 2>/dev/null | head -n1)
        
        # Extract version number (e.g., "git-stack 0.10.20" -> "0.10.20")
        if echo "$version_output" | grep -q "git-stack"; then
            echo "$version_output" | sed 's/.*git-stack[[:space:]]*//' | sed 's/[[:space:]].*//' | head -n1
        else
            echo "unknown"
        fi
    else
        echo "not-installed"
    fi
}

# Get latest git-stack version from crates.io
get_latest_git_stack_version() {
    local latest_version
    if command -v curl >/dev/null 2>&1; then
        latest_version=$(curl -s https://crates.io/api/v1/crates/git-stack | grep -o '"max_version":"[^"]*"' | sed 's/"max_version":"//' | sed 's/"//' 2>/dev/null)
        if [[ -n "$latest_version" ]]; then
            echo "$latest_version"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Install Rust/Cargo using the official installer
install_rust() {
    echo -e "${BLUE}Installing Rust/Cargo...${NC}"
    
    if is_rust_installed; then
        echo -e "${GREEN}✓ Rust/Cargo is already installed${NC}"
        return 0
    fi
    
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: curl is required but not found. Please install curl first.${NC}"
        return 1
    fi
    
    # Download and run the official Rust installer
    echo -e "${YELLOW}Downloading Rust installer...${NC}"
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
        echo -e "${GREEN}✓ Rust/Cargo installed successfully${NC}"
        
        # Source cargo environment for current session
        if [[ -f "$HOME/.cargo/env" ]]; then
            source "$HOME/.cargo/env"
            echo -e "${GREEN}✓ Cargo environment sourced for current session${NC}"
        fi
        
        # Ensure ~/.cargo/bin is in PATH
        ensure_cargo_in_path
        
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install Rust/Cargo${NC}"
        return 1
    fi
}

# Ensure ~/.cargo/bin is in PATH
ensure_cargo_in_path() {
    local cargo_bin="$HOME/.cargo/bin"
    
    if [[ -d "$cargo_bin" ]]; then
        # Check if it's already in PATH
        if echo "$PATH" | tr ':' '\n' | grep -q "^$cargo_bin$"; then
            echo -e "${GREEN}✓ ~/.cargo/bin is already in PATH${NC}"
        else
            echo -e "${YELLOW}Adding ~/.cargo/bin to PATH...${NC}"
            export PATH="$cargo_bin:$PATH"
            echo -e "${GREEN}✓ ~/.cargo/bin added to PATH for current session${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Warning: ~/.cargo/bin directory not found${NC}"
    fi
}

# Install git-stack via Cargo
install_git_stack() {
    echo -e "${BLUE}Installing git-stack...${NC}"
    
    # Ensure Rust/Cargo is installed first
    if ! is_rust_installed; then
        echo -e "${YELLOW}Rust/Cargo not found. Installing it first...${NC}"
        if ! install_rust; then
            echo -e "${RED}❌ Error: Failed to install Rust/Cargo. Cannot install git-stack.${NC}"
            return 1
        fi
    fi
    
    # Ensure ~/.cargo/bin is in PATH
    ensure_cargo_in_path
    
    # Install git-stack
    echo -e "${YELLOW}Installing git-stack via Cargo...${NC}"
    if cargo install git-stack; then
        echo -e "${GREEN}✓ git-stack installed successfully${NC}"
        
        # Register git-stack as a git subcommand
        register_git_stack_subcommand
        
        return 0
    else
        echo -e "${RED}❌ Error: Failed to install git-stack${NC}"
        return 1
    fi
}

# Register git-stack as a git subcommand
register_git_stack_subcommand() {
    local git_stack_path
    local git_exec_dir
    
    # Find git-stack executable
    if command -v git-stack >/dev/null 2>&1; then
        git_stack_path=$(command -v git-stack)
    elif [[ -f "$HOME/.cargo/bin/git-stack" ]]; then
        git_stack_path="$HOME/.cargo/bin/git-stack"
    else
        echo -e "${YELLOW}⚠️  Warning: git-stack executable not found, cannot register as git subcommand${NC}"
        return 1
    fi
    
    # Find git exec directory
    if command -v git >/dev/null 2>&1; then
        git_exec_dir=$(git --exec-path 2>/dev/null || echo "/usr/local/libexec/git-core")
    else
        echo -e "${YELLOW}⚠️  Warning: git not found, cannot register git-stack subcommand${NC}"
        return 1
    fi
    
    # Create symlink for git-stack subcommand
    if [[ -d "$git_exec_dir" ]] && [[ -f "$git_stack_path" ]]; then
        local git_stack_subcommand="$git_exec_dir/git-stack"
        
        # Remove existing symlink if it exists
        [[ -L "$git_stack_subcommand" ]] && rm "$git_stack_subcommand"
        
        # Create new symlink
        if ln -sf "$git_stack_path" "$git_stack_subcommand"; then
            echo -e "${GREEN}✓ git-stack registered as git subcommand${NC}"
        else
            echo -e "${YELLOW}⚠️  Warning: Failed to register git-stack as git subcommand (permission denied?)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Warning: Cannot register git-stack as git subcommand (git exec directory not found)${NC}"
    fi
}

# Upgrade git-stack to latest version (only if newer version available)
upgrade_git_stack() {
    echo -e "${BLUE}Checking git-stack for updates...${NC}"
    
    if ! is_git_stack_installed; then
        echo -e "${YELLOW}git-stack is not installed. Installing it first...${NC}"
        return install_git_stack
    fi
    
    # Ensure Rust/Cargo is installed
    if ! is_rust_installed; then
        echo -e "${YELLOW}Rust/Cargo not found. Installing it first...${NC}"
        if ! install_rust; then
            echo -e "${RED}❌ Error: Failed to install Rust/Cargo. Cannot upgrade git-stack.${NC}"
            return 1
        fi
    fi
    
    # Ensure ~/.cargo/bin is in PATH
    ensure_cargo_in_path
    
    # Get current and latest versions
    local current_version
    local latest_version
    current_version=$(get_git_stack_version)
    latest_version=$(get_latest_git_stack_version)
    
    echo -e "${YELLOW}Current version: $current_version${NC}"
    echo -e "${YELLOW}Latest version: $latest_version${NC}"
    
    # Debug: Show raw version output
    if is_git_stack_installed; then
        echo -e "${BLUE}Debug - Raw version output: $(git-stack --version 2>/dev/null | head -n1)${NC}"
    fi
    
    # Check if upgrade is needed
    if [[ "$current_version" == "$latest_version" ]] && [[ "$latest_version" != "unknown" ]] && [[ "$current_version" != "unknown" ]]; then
        echo -e "${GREEN}✓ git-stack is already at the latest version ($current_version)${NC}"
        return 0
    fi
    
    # Check if we can't determine versions
    if [[ "$latest_version" == "unknown" ]] || [[ "$current_version" == "unknown" ]]; then
        echo -e "${YELLOW}⚠️  Warning: Could not determine version information. Proceeding with upgrade...${NC}"
        echo -e "${YELLOW}  Current: '$current_version', Latest: '$latest_version'${NC}"
    fi
    
    # Upgrade git-stack
    echo -e "${YELLOW}Upgrading git-stack via Cargo...${NC}"
    if cargo install --force git-stack; then
        echo -e "${GREEN}✓ git-stack upgraded successfully${NC}"
        
        # Re-register as git subcommand
        register_git_stack_subcommand
        
        return 0
    else
        echo -e "${RED}❌ Error: Failed to upgrade git-stack${NC}"
        return 1
    fi
}

# Check and upgrade git-stack on demand
check_upgrade_git_stack() {
    echo -e "${BLUE}Checking git-stack status...${NC}"
    
    if ! is_git_stack_installed; then
        echo -e "${YELLOW}git-stack is not installed.${NC}"
        read -p "Would you like to install it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_git_stack
        else
            echo -e "${YELLOW}Installation cancelled.${NC}"
        fi
        return
    fi
    
    # Ensure ~/.cargo/bin is in PATH
    ensure_cargo_in_path
    
    local current_version
    local latest_version
    current_version=$(get_git_stack_version)
    latest_version=$(get_latest_git_stack_version)
    
    echo -e "${YELLOW}Current version: $current_version${NC}"
    echo -e "${YELLOW}Latest version: $latest_version${NC}"
    
    if [[ "$current_version" == "$latest_version" ]] && [[ "$latest_version" != "unknown" ]]; then
        echo -e "${GREEN}✓ git-stack is up to date${NC}"
    else
        echo -e "${YELLOW}A newer version is available.${NC}"
        read -p "Would you like to upgrade? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            upgrade_git_stack
        else
            echo -e "${YELLOW}Upgrade cancelled.${NC}"
        fi
    fi
}

# Main function to setup Rust and git-stack (non-interactive)
setup_rust_and_git_stack() {
    echo -e "${BLUE}Setting up Rust/Cargo and git-stack...${NC}"
    
    # Install Rust if not present
    if ! is_rust_installed; then
        echo -e "${YELLOW}Installing Rust/Cargo...${NC}"
        if ! install_rust; then
            echo -e "${RED}❌ Error: Failed to install Rust/Cargo${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Rust/Cargo is already installed${NC}"
    fi
    
    # Ensure ~/.cargo/bin is in PATH
    ensure_cargo_in_path
    
    # Install or upgrade git-stack (always upgrade to latest)
    if ! is_git_stack_installed; then
        echo -e "${YELLOW}Installing git-stack...${NC}"
        if ! install_git_stack; then
            echo -e "${RED}❌ Error: Failed to install git-stack${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Upgrading git-stack to latest version...${NC}"
        if ! upgrade_git_stack; then
            echo -e "${RED}❌ Error: Failed to upgrade git-stack${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Rust/Cargo and git-stack setup complete!${NC}"
    echo -e "${YELLOW}💡 You can now use:${NC}"
    echo "   - 'cargo' to manage Rust packages"
    echo "   - 'git stack' to use git-stack commands"
    echo "   - 'check_upgrade_git_stack' to check for updates"
}

# Non-interactive setup function for automated installation
# This function is called automatically during dotfiles installation
setup_rust_and_git_stack_auto() {
    echo -e "${BLUE}Automatically setting up Rust/Cargo and git-stack...${NC}"
    
    # Install Rust if not present
    if ! is_rust_installed; then
        echo -e "${YELLOW}Installing Rust/Cargo...${NC}"
        if ! install_rust; then
            echo -e "${RED}❌ Error: Failed to install Rust/Cargo${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Rust/Cargo is already installed${NC}"
    fi
    
    # Ensure ~/.cargo/bin is in PATH
    ensure_cargo_in_path
    
    # Always install or upgrade git-stack to latest version
    if ! is_git_stack_installed; then
        echo -e "${YELLOW}Installing git-stack...${NC}"
        if ! install_git_stack; then
            echo -e "${RED}❌ Error: Failed to install git-stack${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Upgrading git-stack to latest version...${NC}"
        if ! upgrade_git_stack; then
            echo -e "${RED}❌ Error: Failed to upgrade git-stack${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Rust/Cargo and git-stack setup complete!${NC}"
}

# Complete system setup function (includes all automated configurations)
setup_system_auto() {
    echo -e "${BLUE}Setting up complete system configuration...${NC}"
    
    # Setup Rust and git-stack
    setup_rust_and_git_stack_auto
    
    # Install git-sweep
    install_git_sweep
    
    # Configure macOS Finder (only on macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        enable_finder_hidden_files
    fi
    
    echo -e "${GREEN}✅ Complete system setup finished!${NC}"
}

# Git-sweep Management
# These functions handle git-sweep installation and management

# Check if git-sweep is installed
is_git_sweep_installed() {
    command -v git-sweep >/dev/null 2>&1
}

# Install git-sweep via global virtual environment
install_git_sweep() {
    echo -e "${BLUE}Installing git-sweep...${NC}"
    
    if is_git_sweep_installed; then
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

# NX Monorepo Tool Management
# Simple alias approach - follows Shiftsmart's pattern of using local nx versions

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

# Convenience aliases for software management
alias rust-setup='setup_rust_and_git_stack'
alias git-stack-upgrade='upgrade_git_stack'
alias git-stack-check='check_upgrade_git_stack'
alias rust-install='install_rust'
alias git-stack-install='install_git_stack'
alias git-sweep-install='install_git_sweep'
alias show-hidden-files='enable_finder_hidden_files'
alias system-setup='setup_system_auto'
