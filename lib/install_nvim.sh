#!/bin/bash

# Enhanced nvim_config installation script
set -e

echo -e "=== nvim_config Installation Script ===\n"

# Install Lua
if is_installed lua; then
    echo "Lua is already installed."
else
    echo "Installing Lua..."
    LUA="lua-5.4.6"
    LUA_TAR="$LUA.tar.gz"
    downloadTMP "https://www.lua.org/ftp/$LUA_TAR" "$LUA_TAR"
    tarTMP "$LUA_TAR" "$LOCAL_SRC"
    ( cd "$LOCAL_SRC/$LUA" && sudo make all test  && sudo ln -sf $LOCAL_SRC/$LUA/src/lua $LOCAL_BIN/lua && sudo ln -sf $LOCAL_SRC/$LUA/src/lua.h $LOCAL_INCLUDE/lua.h)    
fi

# Install Luarocks
if is_installed luarocks; then
    echo "Luarocks is already installed."
else
    echo "Installing Luarocks and dependencies..."
    LUA_ROCKS_TAR="luarocks-3.12.2.tar.gz"
    LUA_ROCKS_DIR="/tmp/luarocks-3.12.2"
    downloadTMP "https://luarocks.org/releases/$LUA_ROCKS_TAR" "${LUA_ROCKS_TAR}"
    tarTMP "${LUA_ROCKS_TAR}" "/tmp" 
    ( cd "$LUA_ROCKS_DIR" && ./configure && make && sudo make install )
fi

# Install additional packages
distro=$(getDistroID -v)
if [[ "$distro" == "centos10" ]]; then
    echo "This is CentOS"
    sudo dnf config-manager --set-enabled crb
    sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
fi

installPackage "ripgrep"
installPackage "fd-find"

TARGET_DIR="$USER_HOME/.config/nvim"
REPO_URL="https://github.com/tomggg1986/nvim_config.git"

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

echo -e "=== Installation Complete ===\n"