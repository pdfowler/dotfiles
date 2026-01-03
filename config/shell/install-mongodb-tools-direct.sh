#!/bin/bash
# Install MongoDB tools without Homebrew dependencies
# This script downloads and installs MongoDB tools directly from MongoDB

set -e

LOCAL_BIN="$HOME/.local/bin"
MONGO_TOOLS_DIR="$LOCAL_BIN/mongodb-tools"
MONGO_TOOLS_VERSION="100.9.0"  # Latest stable version
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

echo "Installing MongoDB tools v$MONGO_TOOLS_VERSION for $OS-$ARCH..."

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

# Download mongosh
MONGO_SH_URL="https://downloads.mongodb.com/compass/mongosh-${MONGO_TOOLS_VERSION}-${OS}-${ARCH}.tgz"
echo "Downloading mongosh from: $MONGO_SH_URL"
curl -L "$MONGO_SH_URL" | tar -xz

# Download mongodb-database-tools (mongodump, mongorestore, etc.)
MONGO_DB_TOOLS_URL="https://fastdl.mongodb.org/tools/db/mongodb-database-tools-${OS}-${ARCH}-${MONGO_TOOLS_VERSION}.tgz"
echo "Downloading MongoDB database tools from: $MONGO_DB_TOOLS_URL"
curl -L "$MONGO_DB_TOOLS_URL" | tar -xz

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
