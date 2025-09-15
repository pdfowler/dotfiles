#!/bin/bash

# Comprehensive fix for NVM PATH issues
echo "Fixing NVM PATH issues..."

# Step 1: Clean up existing NVM environment
echo "Step 1: Cleaning up existing NVM environment..."

# Unload NVM if it's loaded
if command -v nvm >/dev/null 2>&1; then
    echo "Unloading NVM..."
    nvm unload
fi

# Remove NVM-related paths from PATH
echo "Cleaning PATH of NVM entries..."
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "\.nvm" | tr '\n' ':' | sed 's/:$//')

# Unset NVM environment variables
unset NVM_BIN NVM_INC NVM_DIR NVM_RC_VERSION

# Step 2: Ensure core utilities are available
echo "Step 2: Ensuring core utilities are available..."
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Verify core utilities
echo "Verifying core utilities..."
for cmd in tr tail head sed; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✓ $cmd is available at: $(which $cmd)"
    else
        echo "✗ $cmd is NOT available"
    fi
done

# Step 3: Load configuration files in correct order
echo "Step 3: Loading configuration files..."

# Source paths.sh first
if [[ -f ~/.config/shell/paths.sh ]]; then
    echo "Loading paths.sh..."
    source ~/.config/shell/paths.sh
else
    echo "Warning: paths.sh not found"
fi

# Source env.sh
if [[ -f ~/.config/shell/env.sh ]]; then
    echo "Loading env.sh..."
    source ~/.config/shell/env.sh
else
    echo "Warning: env.sh not found"
fi

# Source aliases.sh
if [[ -f ~/.config/shell/aliases.sh ]]; then
    echo "Loading aliases.sh..."
    source ~/.config/shell/aliases.sh
else
    echo "Warning: aliases.sh not found"
fi

# Step 4: Test the fix
echo "Step 4: Testing the fix..."
echo "Current PATH: $PATH"
echo "Testing @monorepo alias..."

# Test the cd function
cd @monorepo

echo "Test completed!"
echo "Current directory: $(pwd)"



