# My XDG-Compliant Dotfiles

A modern, organized approach to shell configuration using the XDG Base Directory Specification with full cross-shell compatibility and version control integration.

## 🤔 Why This Approach?

### **XDG Specification Benefits**
- **Modern Standard**: Follows XDG Base Directory Specification (used by VS Code, git, gcloud, yarn, etc.)
- **Clean Home Directory**: No proliferation of dot files in `~/`
- **Logical Organization**: Related configurations grouped together
- **Future-Proof**: Increasingly adopted by modern tools

### **Cross-Shell Compatibility** 
- **Shared Configurations**: Common settings work in both bash and zsh
- **Non-Interactive Shell Support**: Environment variables available to scripts, CI/CD
- **Shell-Specific Extensions**: Zsh-only features separated appropriately

### **Version Control Advantages**
- **Cleaner Repository**: Organized structure vs scattered dotfiles
- **Easy Maintenance**: Changes in one place, automatic via symlinks
- **Portable Setup**: Clone + install script = instant environment
- **Private Data Separation**: Sensitive configs stay local (gitignored)

## 🏗️ Architecture

```
~/Development/dotfiles/              # Git repository
├── config/
│   └── shell/                      # XDG-compliant shell configs
│       ├── env.sh                  # Environment variables (cross-shell)
│       ├── paths.sh                # PATH management (cross-shell)
│       ├── aliases.sh              # Aliases and functions (cross-shell)
│       └── zsh/                    # Zsh-specific configurations
├── zshenv                          # Links to XDG configs (key for non-interactive)
├── install.sh                      # Symlink setup script
├── .gitignore                      # Excludes private configs
└── README.md                       # This file

~/.config/shell/                    # Symlinked from repo
├── env.sh          -> ~/Development/dotfiles/config/shell/env.sh
├── paths.sh        -> ~/Development/dotfiles/config/shell/paths.sh  
├── aliases.sh      -> ~/Development/dotfiles/config/shell/aliases.sh
└── private.sh                      # Local-only sensitive data
```

## 🔑 Key Files Explained

### **`~/.zshenv`** - The Critical File
- **Always loaded** by zsh (interactive, non-interactive, login, non-login)
- **Only file** that makes configs available to non-interactive shells
- Sources cross-shell compatible configurations
- **Essential for**: Scripts, CI/CD, remote commands

### **Cross-Shell Files** (`config/shell/*.sh`)
- **POSIX-compatible syntax** - works in bash and zsh
- **Environment variables and PATHs** - available everywhere
- **Conditional loading** - checks for interactive shells when needed

### **Private Configuration** (`~/.config/shell/private.sh`)
- **Not version controlled** (gitignored)
- **Local-only sensitive data**: API keys, tokens, personal settings
- **Automatically created** by install script

## 🚀 Installation

```bash
# Clone the repository
git clone <your-repo-url> ~/Development/dotfiles
cd ~/Development/dotfiles

# Run installation (creates symlinks + backups)
chmod +x install.sh
./install.sh

# Reload configuration
source ~/.zshrc
```

## ✨ Features

### **Shell Loading Strategy**
- **`.zshenv`** → Env, paths, aliases (always loaded by zsh)
- **`.zprofile`** → Login shells + GUI apps: PATH, env, BASH_ENV
- **`.zshrc`** → Interactive zsh: oh-my-zsh, software.sh
- **`.bashrc`** → Env, paths, aliases (when bash sources it)
- **`.bash_profile`** → Login bash: sources .bashrc
- **`BASH_ENV`** → Non-interactive bash: sources `~/.config/shell/bash_env`

### **Cross-Shell Parity**
Config is available in both zsh and bash (interactive and non-interactive):
- **Zsh**: `.zshenv` loads env, paths, aliases for every invocation
- **Bash**: `BASH_ENV` → `bash_env` for non-interactive; `.bashrc` for interactive/login
- **GUI apps** (Cursor, etc.): `.zprofile` sources env so spawned processes inherit BASH_ENV, DOTFILES_ROOT, etc.

**Cursor Agent note**: Agent terminals may default to bash with a custom init. If `gt`, aliases, or env vars are missing, add to `~/.cursor/settings.json` (or Cursor User settings):
```json
"terminal.integrated.automationProfile.osx": { "path": "/bin/zsh" }
```

### **Cross-Shell Testing**
```bash
# Zsh non-interactive
zsh -c 'echo $DOTFILES_ROOT && type gt'

# Bash non-interactive (requires BASH_ENV from parent, e.g. after login)
bash -c 'echo $DOTFILES_ROOT && type gt'
```

### **Automatic Version Switching**
- **NVM** with `nvm use` on directory change (chpwd hook when `.nvmrc` exists)
- **Auto-detection** of `.nvmrc` files

## 🔧 Usage

### **Making Changes**
```bash
# Edit configs in the repo (changes are live via symlinks)
echo 'alias ll="ls -la"' >> ~/Development/dotfiles/config/shell/aliases.sh

# Commit changes
cd ~/Development/dotfiles
git add . && git commit -m "Add ll alias" && git push
```

### **Setting Up New Machine**
```bash
# One command setup!
git clone <repo> ~/Development/dotfiles && ~/Development/dotfiles/install.sh
```

### **Updating**
```bash
cd ~/Development/dotfiles
git pull  # Changes immediately available via symlinks
```

## 📊 Comparison: Traditional vs XDG Approach

| Aspect | Traditional (`~/.zsh_*`) | XDG (`~/.config/shell/`) |
|--------|-------------------------|--------------------------|
| **Home Directory** | Cluttered with dotfiles | Clean, organized |
| **Cross-shell** | Separate files per shell | Shared + shell-specific |
| **Version Control** | Complex symlink management | Simple, logical structure |
| **Portability** | Shell-specific setup | Universal approach |
| **Non-interactive** | Often broken/inconsistent | Properly supported |
| **Maintenance** | Scattered configurations | Centralized, modular |

## 🎯 Best Practices Implemented

### **File Organization Principles**
1. **Separation of Concerns**: Environment, paths, aliases in separate files
2. **Cross-Shell Compatibility**: POSIX-compatible syntax in shared files
3. **Interactive vs Non-Interactive**: Proper detection and handling
4. **Private Data Isolation**: Sensitive configs excluded from version control

### **Loading Order Strategy**
1. **Environment Setup** (`env.sh`) - Always available
2. **PATH Configuration** (`paths.sh`) - Tool availability  
3. **Interactive Features** (`aliases.sh`) - Only when needed
4. **Shell-Specific** (`zsh/`) - Advanced features

### **Version Control Integration**
- **Symlink-based**: Edit in repo, changes immediately live
- **Backup Protection**: Existing configs automatically backed up
- **Private Config Support**: Local-only sensitive data
- **Multi-machine Sync**: Simple clone + install workflow

## 🧪 Verification Commands

```bash
# Verify XDG structure is working
ls -la ~/.config/shell/

# Check symlinks are correct  
readlink ~/.config/shell/env.sh

# Test non-interactive shell support
zsh -c 'echo "EDITOR: $EDITOR, PATH includes: $(echo $PATH | grep -o homebrew)"'

# Verify oh-my-zsh integration
echo $ZSH_THEME

# Test NVM auto-switching
cd /tmp && echo "18" > .nvmrc && cd . && nvm current
```

## 🎉 Why This Setup Wins

This configuration represents a **modern, maintainable approach** that combines:

- ✅ **XDG compliance** for future-proofing
- ✅ **Cross-shell compatibility** for flexibility  
- ✅ **Version control integration** for portability
- ✅ **Non-interactive shell support** for automation
- ✅ **Modular organization** for maintainability
- ✅ **Private data separation** for security

**Result**: A dotfiles setup that's cleaner, more portable, and easier to maintain than traditional approaches while being fully compatible with modern development workflows. 