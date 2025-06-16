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

# Create symlinks for shell configs
echo -e "${YELLOW}Creating shell configuration symlinks...${NC}"
create_symlink "$DOTFILES_DIR/config/shell/env.sh" "$HOME/.config/shell/env.sh"
create_symlink "$DOTFILES_DIR/config/shell/paths.sh" "$HOME/.config/shell/paths.sh"
create_symlink "$DOTFILES_DIR/config/shell/aliases.sh" "$HOME/.config/shell/aliases.sh"

# Create symlinks for shell-specific files
echo -e "${YELLOW}Creating shell-specific configuration symlinks...${NC}"
create_symlink "$DOTFILES_DIR/zshenv" "$HOME/.zshenv"
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

echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
echo -e "${YELLOW}💡 Don't forget to:${NC}"
echo "  1. Add sensitive data to ~/.config/shell/private.sh (all 'private' files are git ignored)"
echo "  2. Run 'update' or restart this and other terminal sessions"
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    echo "  3. Initialize git repo: cd $DOTFILES_DIR && git init"
fi 