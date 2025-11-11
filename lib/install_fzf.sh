#!/bin/bash

# Enhanced fzf installation script with better error handling
set -e

echo -e "=== fzf Installation Script ===\n"

FZF_DIR="$USER_HOME/.fzf"

echo "Installing to: $USER_HOME"

# Check if fzf is already installed
if [ -d "$FZF_DIR" ]; then
    echo "fzf appears to be already installed at $FZF_DIR"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "Removing existing installation..."
    rm -rf "$FZF_DIR"
fi

# Clone the repository
echo "Cloning fzf repository..."
if git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"; then
    echo "✓ Repository cloned successfully"
else
    echo "✗ Failed to clone repository"
    exit 1
fi

# Run the install script
echo "Running fzf installer..."
if [ -f "$FZF_DIR/install" ]; then
    chmod +x "$FZF_DIR/install"
     # Run the installer with all options
    if "$FZF_DIR/install" --all; then
        echo "✓ fzf installed successfully"
    else
        echo "✗ fzf installation failed"
        exit 1
    fi
else
    echo "✗ Install script not found at $FZF_DIR/install"
    exit 1
fi

echo "fzf has been installed to $FZF_DIR"
echo -e "=== Installation Complete ===\n"


