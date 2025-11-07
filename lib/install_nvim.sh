#!/bin/bash

# Enhanced nvim_config installation script
set -e

echo "=== nvim_config Installation Script ==="


TARGET_DIR="$USER_HOME/.config/nvim"
REPO_URL="https://github.com/tomggg1986/nvim_config.git"

echo "Target directory: $TARGET_DIR"

# Handle existing directory
if [ -d "$TARGET_DIR" ]; then
    echo "Removing existing directory..."
    rm -rf "$TARGET_DIR"     
fi

# Clone the repository
echo "Cloning nvim_config repository..."
if git clone "$REPO_URL" "$TARGET_DIR"; then
    echo "✓ Repository cloned successfully"
else
    echo "❌ Clone failed completely. Please check:"
    exit 1
fi

# Verify the installation
if [ -d "$TARGET_DIR" ] && [ -d "$TARGET_DIR/.git" ]; then
    echo "✓ Installation verified"
    echo "Repository contents:"
    ls -la "$TARGET_DIR"
else
    echo "❌ Installation verification failed"
    exit 1
fi

echo "=== Installation Complete ==="