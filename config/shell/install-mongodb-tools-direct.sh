#!/bin/bash
# Install MongoDB tools without Homebrew dependencies
# mongosh: latest from GitHub (2.x), macOS assets are .zip
# mongodb-database-tools: from fastdl.mongodb.org (100.x)

set -e

LOCAL_BIN="$HOME/.local/bin"
MONGO_TOOLS_DIR="$LOCAL_BIN/mongodb-tools"
MONGO_DB_TOOLS_VERSION="100.14.1"  # mongodump/mongorestore etc.
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="x86_64"
        ;;
    arm64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Ensure ~/.local/bin exists and is in PATH
mkdir -p "$LOCAL_BIN"
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "⚠️  Adding $LOCAL_BIN to PATH..."
    echo "Add this to your shell profile:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Clean up any existing installation
if [[ -d "$MONGO_TOOLS_DIR" ]]; then
    echo "Removing existing MongoDB tools..."
    rm -rf "$MONGO_TOOLS_DIR"
fi

# Create tools directory
mkdir -p "$MONGO_TOOLS_DIR"
cd "$MONGO_TOOLS_DIR"

# mongosh: resolve latest from GitHub, download .zip for darwin
GH_JSON=$(curl -sS "https://api.github.com/repos/mongodb-js/mongosh/releases/latest")
if command -v jq >/dev/null 2>&1; then
    MONGO_SH_VERSION=$(printf '%s' "$GH_JSON" | jq -r '.tag_name | ltrimstr("v")')
else
    MONGO_SH_VERSION=$(printf '%s' "$GH_JSON" | grep -o '"tag_name": *"v[^"]*"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
fi
[[ -z "$MONGO_SH_VERSION" || "$MONGO_SH_VERSION" == "null" ]] && MONGO_SH_VERSION="2.7.0"
GH_ARCH="$ARCH"
[[ "$GH_ARCH" == "x86_64" ]] && GH_ARCH="x64"
MONGO_SH_URL="https://github.com/mongodb-js/mongosh/releases/download/v${MONGO_SH_VERSION}/mongosh-${MONGO_SH_VERSION}-darwin-${GH_ARCH}.zip"
echo "Downloading mongosh v${MONGO_SH_VERSION} from: $MONGO_SH_URL"
curl -L -o mongosh.zip "$MONGO_SH_URL"
unzip -q -o mongosh.zip && rm -f mongosh.zip

# mongodb-database-tools: tgz from fastdl (often 403); fallback to Homebrew
MONGO_DB_TOOLS_URL="https://fastdl.mongodb.org/tools/db/mongodb-database-tools-${OS}-${ARCH}-${MONGO_DB_TOOLS_VERSION}.tgz"
DB_TOOLS_TGZ="$MONGO_TOOLS_DIR/db-tools.tgz"
echo "Downloading MongoDB database tools v${MONGO_DB_TOOLS_VERSION} from: $MONGO_DB_TOOLS_URL"
if curl -sSfL -o "$DB_TOOLS_TGZ" "$MONGO_DB_TOOLS_URL" && [[ -s "$DB_TOOLS_TGZ" ]]; then
    SIZE=$(stat -f%z "$DB_TOOLS_TGZ" 2>/dev/null || stat -c%s "$DB_TOOLS_TGZ" 2>/dev/null)
    if [[ -n "$SIZE" && "$SIZE" -gt 1000 ]] && tar -xzf "$DB_TOOLS_TGZ"; then
        rm -f "$DB_TOOLS_TGZ"
    else
        rm -f "$DB_TOOLS_TGZ"
        if command -v brew >/dev/null 2>&1; then
            echo "Direct download blocked (403). Installing MongoDB database tools via Homebrew..."
            brew tap mongodb/brew 2>/dev/null || true
            brew install mongodb-database-tools || true
        else
            echo "⚠ Direct download blocked. Install manually: https://www.mongodb.com/try/download/database-tools"
        fi
    fi
else
    rm -f "$DB_TOOLS_TGZ"
    if command -v brew >/dev/null 2>&1; then
        echo "Direct download blocked (403). Installing MongoDB database tools via Homebrew..."
        brew tap mongodb/brew 2>/dev/null || true
        brew install mongodb-database-tools || true
    else
        echo "⚠ Direct download blocked. Install manually: https://www.mongodb.com/try/download/database-tools"
    fi
fi

# Find the actual binary directories
MONGO_SH_BIN=$(find . -name "mongosh" -type f | head -1 | xargs dirname)
MONGO_DB_TOOLS_BIN=$(find . -name "mongodump" -type f | head -1 | xargs dirname)

echo "Creating symlinks in $LOCAL_BIN..."

# Create symlinks for mongosh
if [[ -n "$MONGO_SH_BIN" ]]; then
    ln -sf "$MONGO_TOOLS_DIR/$MONGO_SH_BIN/mongosh" "$LOCAL_BIN/mongosh"
    echo "✓ mongosh installed"
fi

# Create symlinks for database tools
if [[ -n "$MONGO_DB_TOOLS_BIN" ]]; then
    for tool in mongodump mongorestore mongoexport mongoimport mongostat mongotop bsondump; do
        if [[ -f "$MONGO_TOOLS_DIR/$MONGO_DB_TOOLS_BIN/$tool" ]]; then
            ln -sf "$MONGO_TOOLS_DIR/$MONGO_DB_TOOLS_BIN/$tool" "$LOCAL_BIN/$tool"
            echo "✓ $tool installed"
        fi
    done
fi

echo ""
echo "✅ MongoDB tools installed successfully!"
echo ""
echo "Installed tools:"
ls -la "$LOCAL_BIN" | grep mongo
echo ""
echo "Test installation:"
echo "  mongosh --version"
echo "  mongodump --version"
echo ""
echo "These tools are completely independent of Homebrew and Node.js versions."
