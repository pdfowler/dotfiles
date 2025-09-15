# NVM PATH Fix for Dotfiles

## Problem
When using the custom `cd()` function with aliases like `@monorepo`, you may encounter errors like:
```
nvm:7: command not found: tr
nvm:7: command not found: tr
nvm_version:21: command not found: tail
nvm_resolve_alias:17: command not found: head
nvm_resolve_alias:17: command not found: sed
```

This happens because NVM is loaded before the PATH is fully configured, causing core utilities like `tr`, `tail`, `head`, and `sed` to not be available.

## Root Cause
The issue occurs when:
1. NVM is loaded in the shell session
2. The custom `cd()` function is called
3. NVM tries to use core utilities that aren't in the PATH yet
4. This causes the "command not found" errors

## Solutions

### Solution 1: Use the fix_nvm_path function (Recommended)
If you're experiencing this issue in your current shell session:

```bash
# Run this function to fix the current session
fix_nvm_path

# Then reload your shell configuration
source ~/.zshenv
```

### Solution 2: Use the fix script
Run the comprehensive fix script:

```bash
cd ~/Development/dotfiles
./fix-nvm-path.sh
```

### Solution 3: Manual fix
If you prefer to fix it manually:

```bash
# 1. Unload NVM
nvm unload

# 2. Clean up NVM from PATH
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.nvm" | tr '\n' ':' | sed 's/:$//')

# 3. Unset NVM environment variables
unset NVM_BIN NVM_INC NVM_DIR NVM_RC_VERSION

# 4. Ensure core utilities are available
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# 5. Reload your shell configuration
source ~/.zshenv
```

## Prevention
The dotfiles have been updated to prevent this issue from happening in new shell sessions:

1. **paths.sh**: Only loads NVM in interactive shells and ensures core utilities are available first
2. **zshenv**: Only loads aliases in interactive zsh shells
3. **aliases.sh**: Added safety checks and debug functions

## Debug Functions
The following functions are available for debugging:

```bash
# Enable debug output for cd function
debug_cd_on

# Disable debug output for cd function
debug_cd_off

# Test the cd function
test_cd

# Fix NVM PATH issues
fix_nvm_path
```

## Testing
To test if the fix is working:

```bash
# Test the @monorepo alias
cd @monorepo

# If successful, you should change to the monorepo directory without errors
pwd
# Should show: /Users/pdfowler/Development/shiftsmart/services/monorepo
```

## File Changes Made
The following files were modified to fix this issue:

1. **config/shell/paths.sh**: Added safe NVM loading and PATH cleanup functions
2. **config/shell/aliases.sh**: Added debug functions and improved error handling
3. **config/shell/zshenv**: Added better shell type checking
4. **fix-nvm-path.sh**: Created comprehensive fix script
5. **NVM-FIX-README.md**: This documentation file

## Notes
- The fix ensures that core utilities (`tr`, `tail`, `head`, `sed`) are available before NVM is loaded
- NVM is only loaded in interactive shells to avoid issues with scripts
- The custom `cd()` function now has debug capabilities that can be enabled with `DEBUG_CD=1`
- All changes are backward compatible and won't break existing functionality



