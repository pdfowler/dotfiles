#!/bin/bash

# Test script for NVM nounset fix
# This script tests the fix for the NVM hook and cd problems

echo "Testing NVM nounset fix..."
echo "=========================="

# Source the aliases to get our fix functions
source config/shell/aliases.sh

echo "1. Testing NVM_NO_USE variable handling..."
echo "   Setting NVM_NO_USE to unset state..."

# Unset NVM_NO_USE to simulate the problematic state
unset NVM_NO_USE

echo "   Testing _zsh_nvm_load_wrapper function..."

# Test our wrapper function directly
if declare -f _zsh_nvm_load_wrapper >/dev/null 2>&1; then
    echo "   ✓ _zsh_nvm_load_wrapper function exists"
    
    # Test the wrapper with unset NVM_NO_USE
    if _zsh_nvm_load_wrapper 2>/dev/null; then
        echo "   ✓ Wrapper handles unset NVM_NO_USE correctly"
    else
        echo "   ✗ Wrapper failed with unset NVM_NO_USE"
    fi
else
    echo "   ✗ _zsh_nvm_load_wrapper function not found"
fi

echo ""
echo "2. Testing fix_nvm_nounset function..."
if declare -f fix_nvm_nounset >/dev/null 2>&1; then
    echo "   ✓ fix_nvm_nounset function exists"
    echo "   Running fix_nvm_nounset..."
    fix_nvm_nounset
else
    echo "   ✗ fix_nvm_nounset function not found"
fi

echo ""
echo "3. Testing comprehensive fix..."
if declare -f fix_nvm_comprehensive >/dev/null 2>&1; then
    echo "   ✓ fix_nvm_comprehensive function exists"
    echo "   Running fix_nvm_comprehensive..."
    fix_nvm_comprehensive
else
    echo "   ✗ fix_nvm_comprehensive function not found"
fi

echo ""
echo "4. Testing node command availability..."
if command -v node >/dev/null 2>&1; then
    echo "   ✓ node command is available"
    echo "   Node version: $(node --version 2>/dev/null || echo 'Failed to get version')"
else
    echo "   ✗ node command not available"
fi

echo ""
echo "5. Testing other Node.js commands..."
for cmd in npm yarn nx npx; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "   ✓ $cmd command is available"
    else
        echo "   ✗ $cmd command not available"
    fi
done

echo ""
echo "Test complete!"
echo "If you see any ✗ marks above, the fix may need adjustment."
echo "If all tests pass, the NVM nounset issue should be resolved."
