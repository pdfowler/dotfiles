#!/bin/bash

# Dotfiles installation script
# This script creates symlinks from your home directory to your dotfiles repo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Setting up dotfiles from: ${DOTFILES_DIR}${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p ~/.config/shell/zsh

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    
    # If target exists and is not a symlink, back it up
    if [[ -e "$target" && ! -L "$target" ]]; then
        echo -e "${YELLOW}Backing up existing $target to $target.backup${NC}"
        mv "$target" "$target.backup"
    fi
    
    # Remove existing symlink if it exists
    [[ -L "$target" ]] && rm "$target"
    
    # Create the symlink
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓ Linked $source -> $target${NC}"
}

install_packages() {
    echo -e "${YELLOW}Installing packages...${NC}"
    local has_cursor_cli=""
    if command -v cursor-agent >/dev/null 2>&1; then
        has_cursor_cli="$(which cursor-agent)"
    fi

    if [[ ! $has_cursor_cli ]]; then
        echo -e "${YELLOW}Installing cursor-agent...${NC}"
        curl https://cursor.com/install -fsS | bash > /dev/null 2>&1
    else 
        echo -e "${YELLOW}Updating cursor-agent...${NC}"
        cursor-agent update > /dev/null 2>&1
    fi

    # install setuptools to avoid nodegyp/unixdgram errors
    if ! command -v pip3 >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing pip3...${NC}"
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
        python3 get-pip.py
        rm get-pip.py
    fi

    # Check if setuptools is available (it's a Python package, not a command)
    if ! python3 -c "import setuptools" 2>/dev/null; then
        echo -e "${YELLOW}Installing setuptools...${NC}"
        # Temporarily disable virtualenv requirement for this installation
        PIP_REQUIRE_VIRTUALENV=false pip3 install setuptools
    fi

    # Set up global virtual environment for tools like uv/uvx
    echo -e "${YELLOW}Setting up global virtual environment...${NC}"
    if [[ -f "$DOTFILES_DIR/config/shell/aliases.sh" ]]; then
        # Source the aliases to get the create_global_venv function
        source "$DOTFILES_DIR/config/shell/aliases.sh"
        create_global_venv
        echo -e "${GREEN}✓ Global virtual environment setup complete${NC}"
    else
        echo -e "${YELLOW}Warning: aliases.sh not found, skipping global venv setup${NC}"
    fi

    # Install Rust/Cargo, git-stack, and configure system
    echo -e "${YELLOW}Setting up development tools and system configuration...${NC}"
    if [[ -f "$DOTFILES_DIR/config/shell/software.sh" ]]; then
        # Source the software functions
        source "$DOTFILES_DIR/config/shell/software.sh"
        setup_system_auto
        echo -e "${GREEN}✓ Development tools and system configuration complete${NC}"
        
        # Setup shell completions
        echo -e "${YELLOW}Setting up shell completions...${NC}"
        setup_completions
        echo -e "${GREEN}✓ Shell completions setup complete${NC}"
    else
        echo -e "${YELLOW}Warning: software.sh not found, skipping development tools setup${NC}"
    fi
}

# Create symlinks for cross-shell compatible configs
echo -e "${YELLOW}Creating cross-shell configuration symlinks...${NC}"
create_symlink "$DOTFILES_DIR/config/shell/env.sh" "$HOME/.config/shell/env.sh"
create_symlink "$DOTFILES_DIR/config/shell/paths.sh" "$HOME/.config/shell/paths.sh"
create_symlink "$DOTFILES_DIR/config/shell/aliases.sh" "$HOME/.config/shell/aliases.sh"
create_symlink "$DOTFILES_DIR/config/shell/software.sh" "$HOME/.config/shell/software.sh"
create_symlink "$DOTFILES_DIR/config/shell/cleanup-merged-branches.sh" "$HOME/.config/shell/cleanup-merged-branches.sh"

# Create symlinks for shell-specific files
echo -e "${YELLOW}Creating shell-specific configuration symlinks...${NC}"
create_symlink "$DOTFILES_DIR/config/shell/zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/config/shell/bashrc" "$HOME/.bashrc"

# Optional: Create a private config file if it doesn't exist
if [[ ! -f ~/.config/shell/private.sh ]]; then
    echo -e "${YELLOW}Creating private config file...${NC}"
    cat > ~/.config/shell/private.sh << 'EOF'
# Private configuration (not version controlled)
# Add sensitive environment variables, tokens, etc. here

# Example:
# export GITHUB_TOKEN="your_token_here"
# export API_KEY="your_api_key_here"
EOF
    echo -e "${GREEN}✓ Created ~/.config/shell/private.sh${NC}"
fi

install_packages

# Setup git aliases for branch cleanup
echo -e "${YELLOW}Setting up git aliases...${NC}"
git config --global alias.prune-local '!$HOME/.config/shell/cleanup-merged-branches.sh'
echo -e "${GREEN}✓ Git aliases configured${NC}"

echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
echo -e "${YELLOW}💡 Don't forget to:${NC}"
echo "  1. Add sensitive data to ~/.config/shell/private.sh (all 'private' files are git ignored)"
echo "  2. Run 'update' or restart this and other terminal sessions"
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    echo "  3. Initialize git repo: cd $DOTFILES_DIR && git init"
fi

echo -e "${YELLOW}🐍 Python Virtual Environment:${NC}"
echo "  • Use 'gvenv' to activate global virtual environment for tools like uv/uvx"
echo "  • Use 'gdeactivate' to deactivate the global virtual environment"
echo ""
echo -e "${YELLOW}🔧 Git Branch Cleanup:${NC}"
echo "  • Use 'git prune-local' to delete branches with merged PRs"
echo "  • Use 'git prune-local --list' to preview what would be deleted"
echo "  • Use 'git prune-local --closed' to include closed PRs"
echo "  • Use 'git prune-local --closed --list' to preview all" 