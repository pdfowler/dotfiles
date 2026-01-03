#!/bin/bash

# Auto-fix script for NVM PATH corruption issues
# This script automatically detects and fixes NVM-related PATH problems

echo "🔧 Auto-fixing NVM PATH corruption issues..."

# Check if core utilities are missing
missing_utils=()
for util in tr tail head sed; do
    if ! command -v "$util" >/dev/null 2>&1; then
        missing_utils+=("$util")
    fi
done

if [[ ${#missing_utils[@]} -gt 0 ]]; then
    echo "❌ Missing core utilities: ${missing_utils[*]}"
    echo "🔧 Applying NVM PATH corruption fix..."
    
    # Source the aliases to get the fix functions
    if [[ -f ~/.config/shell/aliases.sh ]]; then
        source ~/.config/shell/aliases.sh
        fix_nvm_path_corruption
    else
        echo "⚠️  aliases.sh not found, applying manual fix..."
        
        # Manual fix
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        
        # Clean up any duplicate or problematic NVM paths
        export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
        
        # Ensure NVM paths are properly appended (not replacing system paths)
        if [[ -n "${NVM_BIN:-}" ]] && [[ -d "$NVM_BIN" ]]; then
            export PATH="$PATH:$NVM_BIN"
        fi
    fi
    
    # Verify the fix
    echo "✅ Verifying fix..."
    for util in tr tail head sed; do
        if command -v "$util" >/dev/null 2>&1; then
            echo "✅ $util: $(which $util)"
        else
            echo "❌ $util: still missing"
        fi
    done
    
    echo "🎉 NVM PATH corruption fix applied!"
else
    echo "✅ All core utilities are available - no fix needed"
fi

echo "Current PATH: $PATH"

