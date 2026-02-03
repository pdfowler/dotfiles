# GUI Application Environment Fix

## Problem

macOS GUI applications (Cursor, VSCode, Fork, etc.) don't inherit shell environment variables from `.zshenv` or `.zshrc`. They get their environment from login shells, which read `.zprofile` before `.zshenv`.

## Root Cause (Discovered Jan 2026)

When the dotfiles were updated on Jan 27, 2026 to hardcode `HOMEBREW_PREFIX` environment variables (commit c42cbca), this inadvertently broke GUI applications. Here's what happened:

1. **What `brew shellenv` does**: When `HOMEBREW_PREFIX` is NOT already set, `brew shellenv` outputs:
   ```bash
   eval "$(/usr/bin/env PATH_HELPER_ROOT="/opt/homebrew" /usr/libexec/path_helper -s)"
   ```

2. **What `path_helper` does**: macOS's `/usr/libexec/path_helper` reads `/etc/paths` and `/etc/paths.d/*` to build the system PATH. This is how GUI apps traditionally get their PATH on macOS.

3. **The problem**: By setting `HOMEBREW_PREFIX` in `env.sh` (sourced early via `.zshenv`), `brew shellenv` now returns nothing, so `path_helper` never runs. Terminal shells work because they inherit a good PATH, but GUI apps don't have one yet.

4. **Why it worked before**: The old code had complex timeout logic that eventually called `eval "$BREW_ENV"` which included the `path_helper` call.

## Solution: .zprofile (The macOS Way)

macOS reads `.zprofile` for login shells BEFORE `.zshenv`. This is the standard place to set up PATH for GUI applications.

### What Was Done

1. **Created `config/shell/zprofile`**
   - Calls macOS's `path_helper` to set up system PATH
   - Adds Homebrew paths explicitly
   - Sources `.zshenv` to get all other environment setup

2. **Updated `install.sh`**
   - Added symlink: `~/.zprofile` → `dotfiles/config/shell/zprofile`

3. **Cleaned up `config/shell/paths.sh`**
   - Removed the background process killer for brew shellenv
   - Added comments explaining why we don't call `brew shellenv`

4. **Removed LaunchAgent workaround**
   - Deleted the temporary `~/Library/LaunchAgents/setenv.path.plist`
   - This was a workaround that's no longer needed

## macOS Shell Loading Order

For login shells (what GUI apps use):

1. `/etc/zprofile` (system-wide, calls `path_helper` for basic PATH)
2. **`~/.zprofile`** ← **This was missing! Now added.**
3. `/etc/zshenv` (system-wide)
4. `~/.zshenv` (our main config)
5. `/etc/zshrc` (system-wide)
6. `~/.zshrc` (interactive customization)

For non-interactive shells (like git hooks):
1. `/etc/zshenv`
2. `~/.zshenv`

## How to Apply

If you're setting up a new machine:
```bash
cd ~/Development/dotfiles
./install.sh
```

If you're updating an existing setup:
```bash
cd ~/Development/dotfiles
ln -sf $(pwd)/config/shell/zprofile ~/.zprofile
```

Then **log out and log back in** (or restart your Mac).

## Testing

After logging back in:

1. **Test GUI apps**:
   - Open Cursor and try a git commit from the GUI sidebar
   - Open Fork and verify it can authenticate

2. **Verify PATH**:
   ```bash
   # In a new terminal:
   echo $PATH | tr ':' '\n' | head -10
   
   # Should show:
   # /opt/homebrew/bin
   # /opt/homebrew/sbin
   # /usr/local/bin
   # ... etc
   ```

3. **Test commands**:
   ```bash
   which npx    # Should find it
   which gpg    # Should find it
   which gh     # Should find it
   ```

## Why This Is Better Than LaunchAgent

- ✅ **Native macOS approach**: Uses the built-in shell loading order
- ✅ **Integrated into dotfiles**: Managed by your repo, tracked in git
- ✅ **Version-agnostic**: No hardcoded node versions
- ✅ **Maintainable**: Changes to shell config automatically apply
- ✅ **Standard practice**: This is how macOS is designed to work

## Troubleshooting

### Still getting "command not found" errors

1. Verify `.zprofile` symlink exists:
   ```bash
   ls -la ~/.zprofile
   # Should show: ~/.zprofile -> /Users/you/Development/dotfiles/config/shell/zprofile
   ```

2. Test `.zprofile` manually:
   ```bash
   source ~/.zprofile
   echo $PATH
   ```

3. Ensure you've logged out and back in (restart is even better)

### Git credential helper not working

Verify `gh` is in PATH:
```bash
which gh
# Should output: /opt/homebrew/bin/gh

gh auth status
# Should show you're logged in
```

If not authenticated:
```bash
gh auth login
```

## Files Modified

- ✅ Created: `config/shell/zprofile`
- ✅ Updated: `install.sh` (added .zprofile symlink)
- ✅ Updated: `config/shell/paths.sh` (removed brew shellenv cleanup, added comments)
- ✅ Removed: `~/Library/LaunchAgents/setenv.path.plist` (temporary workaround)
- ✅ Created: `~/.zprofile` symlink

## Related Configuration

Your shell configuration files work together:

- `~/.zprofile` - Login shell setup (PATH for GUI apps) ← **NEW**
- `~/.zshenv` - Loaded by all zsh shells (interactive and non-interactive)
- `~/.zshrc` - Interactive shell customization (oh-my-zsh, aliases, etc.)
- `~/.config/shell/env.sh` - Cross-shell environment variables
- `~/.config/shell/paths.sh` - Modular PATH configuration
- `~/.config/shell/aliases.sh` - Shell aliases and functions

The `.zprofile` ensures GUI applications get the same PATH that terminal shells receive.

