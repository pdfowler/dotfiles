# XDG Dotfiles Version Control Workflow

## 🚀 Initial Setup

```bash
# 1. Clone your dotfiles repo
git clone https://github.com/yourusername/dotfiles.git ~/Development/dotfiles

# 2. Run the install script  
cd ~/Development/dotfiles
./install.sh

# 3. Your configs are now symlinked and version controlled!
```

## ✏️ Making Changes

```bash
# Edit files in your repo (they're automatically live via symlinks)
echo 'alias myalias="echo hello"' >> ~/Development/dotfiles/config/shell/aliases.sh

# Commit and push
cd ~/Development/dotfiles
git add .
git commit -m "Add new alias"
git push origin main
```

## 💻 Setting Up Another Machine

```bash
# Just clone and install - instant setup!
git clone https://github.com/yourusername/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
./install.sh
```

## 🔄 Staying Updated

```bash
# Pull latest changes
cd ~/Development/dotfiles
git pull

# Changes are immediately available (thanks to symlinks!)
source ~/.zshrc
```

## 🔒 Private Data Management

```bash
# Add sensitive data to the local-only private config
echo 'export SECRET_KEY="abc123"' >> ~/.config/shell/private.sh

# This file is gitignored, so it won't be committed
``` 