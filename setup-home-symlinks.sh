#!/bin/bash

# Create HOME_CONFIG directory if it doesn't exist
mkdir -p HOME_CONFIG

# List of dotfiles/directories you want to symlink
# Add or remove items from this array as needed
DOTFILES=(
    ".gitconfig"
    ".zshrc" 
    ".zprofile"
    ".viminfo"
    ".yarnrc"
    ".boto"
    ".config"
    ".docker"
    ".ssh"
    ".local"
    ".cache"
    ".npm"
    ".oh-my-zsh"
    ".nvm"
    ".pyenv"
    ".cursor"
    ".gsutil"
    ".rippling"
    ".dvdcss"
    ".zsh_history"
    ".zcompdump-brock-5.9"
    ".zcompdump-Patrick's Mac Studio-5.9"
    ".zshrc.backup"
    ".zshrc.pre-oh-my-zsh"
)

echo "Creating symlinks for dotfiles in HOME_CONFIG directory..."

for dotfile in "${DOTFILES[@]}"; do
    source_path="$HOME/$dotfile"
    target_path="HOME_CONFIG/$dotfile"
    
    # Check if source exists
    if [[ -e "$source_path" ]]; then
        # Remove existing symlink or file if it exists
        if [[ -L "$target_path" || -e "$target_path" ]]; then
            rm -rf "$target_path"
        fi
        
        # Create the symlink
        ln -s "$source_path" "$target_path"
        echo "✓ Linked $dotfile"
    else
        echo "⚠ Skipped $dotfile (not found in home directory)"
    fi
done

echo "Done! Dotfiles are now available in the HOME_CONFIG directory."
echo "You can now add HOME_CONFIG to your VS Code workspace." 