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

    # Set up global virtual environment first (avoids PEP 668 / externally-managed system Python)
    echo -e "${YELLOW}Setting up global virtual environment...${NC}"
    if [[ -f "$DOTFILES_DIR/config/shell/aliases.sh" ]]; then
        source "$DOTFILES_DIR/config/shell/aliases.sh"
        create_global_venv
        echo -e "${GREEN}✓ Global virtual environment setup complete${NC}"
        # Install setuptools in venv (for nodegyp/unixdgram when using venv Python)
        if ! "$HOME/.local/venv/bin/python" -c "import setuptools" 2>/dev/null; then
            echo -e "${YELLOW}Installing setuptools in global venv...${NC}"
            "$HOME/.local/venv/bin/pip" install setuptools
        fi
    else
        echo -e "${YELLOW}Warning: aliases.sh not found, skipping global venv setup${NC}"
    fi

    # Install Common System Tools
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
create_symlink "$DOTFILES_DIR/config/shell/install-mongodb-tools-direct.sh" "$HOME/.config/shell/install-mongodb-tools-direct.sh"
create_symlink "$DOTFILES_DIR/config/shell/cleanup-merged-branches.sh" "$HOME/.config/shell/cleanup-merged-branches.sh"
create_symlink "$DOTFILES_DIR/config/shell/bash_env" "$HOME/.config/shell/bash_env"

# Create symlinks for shell-specific files
echo -e "${YELLOW}Creating shell-specific configuration symlinks...${NC}"
create_symlink "$DOTFILES_DIR/config/shell/zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/config/shell/zprofile" "$HOME/.zprofile"
create_symlink "$DOTFILES_DIR/config/shell/zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/config/shell/bashrc" "$HOME/.bashrc"
create_symlink "$DOTFILES_DIR/config/shell/bash_profile" "$HOME/.bash_profile"
[[ -f "$DOTFILES_DIR/config/shell/zsh/.p10k.zsh" ]] && create_symlink "$DOTFILES_DIR/config/shell/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Optional: Create a private config file if it doesn't exist
if [[ ! -f ~/.config/shell/private.sh ]]; then
    echo -e "${YELLOW}Creating private config file...${NC}"
    cat > ~/.config/shell/private.sh << 'EOF'
# Private configuration (not version controlled)
# Add sensitive environment variables, tokens, etc. here

# Examples (uncomment and set values):
# export GITHUB_TOKEN="your_token_here"
# export ARPALUS_REGISTRY_TOKEN="your_arpalus_jwt"
# export PNPM_HOME="$HOME/Library/pnpm"
# [[ -n "$PNPM_HOME" ]] && case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac
EOF
    echo -e "${GREEN}✓ Created ~/.config/shell/private.sh${NC}"
fi

# Optional: Machine-specific config (OrbStack, local overrides; not in repo)
if [[ ! -f ~/.config/shell/local.sh ]]; then
    echo -e "${YELLOW}Creating local (machine-specific) config file...${NC}"
    cat > ~/.config/shell/local.sh << 'EOF'
# Machine-specific configuration (not version controlled)
# Add computer-specific overrides here, e.g.:
# source ~/.orbstack/shell/init.zsh  # OrbStack
EOF
    echo -e "${GREEN}✓ Created ~/.config/shell/local.sh${NC}"
fi

install_packages

# Setup git aliases
echo -e "${YELLOW}Setting up git aliases...${NC}"
git config --global alias.prune-local '!$HOME/.config/shell/cleanup-merged-branches.sh'
git config --global alias.relink '!BRANCH=$(git rev-parse --abbrev-ref HEAD) && git branch --set-upstream-to=origin/$BRANCH && echo "✅ Linked $BRANCH to origin/$BRANCH"'
git config --global alias.sync-main '!git fetch origin && git update-ref refs/heads/main refs/remotes/origin/main && echo "✅ Synced main branch from origin"'
echo -e "${GREEN}✓ Git aliases configured${NC}"

echo -e "${GREEN}✅ Dotfiles installation complete!${NC}"
echo -e "${YELLOW}💡 Don't forget to:${NC}"
echo "  1. Add sensitive data to ~/.config/shell/private.sh (all 'private' files are git ignored)"
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    echo "  2. Initialize git repo: cd $DOTFILES_DIR && git init"
fi
echo ""
# Reload shell config in this session (update is from aliases.sh, already sourced by install_packages)
if type update &>/dev/null; then
    update || true
    echo -e "${YELLOW}💡 Restart other terminal sessions (or run 'update' from zsh) to pick up changes.${NC}"
else
    echo -e "${YELLOW}💡 Run 'source ~/.zshenv' and 'source ~/.zshrc' (or restart) to pick up changes.${NC}"
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