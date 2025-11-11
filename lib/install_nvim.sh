#!/bin/bash

# Enhanced nvim_config installation script
set -e

echo -e "=== nvim_config Installation Script ===\n"

echo "Install Lua if not already installed."
if is_installed lua; then
    echo "Lua is already installed."
else
    echo "Installing Lua..."
    downloadTMP "https://www.lua.org/ftp/lua-5.4.6.tar.gz" "lua-5.4.6.tar.gz"
    tarTMP "lua-5.4.6.tar.gz" "$LOCAL_SRC"
    ( cd "$LOCAL_SRC/lua-5.4.6" && sudo make all test  && sudo ln -sf $LOCAL_SRC/lua-5.4.6/src/lua $LOCAL_BIN/lua && sudo ln -sf $LOCAL_SRC/lua-5.4.6/src/lua.h $LOCAL_INCLUDE/lua.h)    
fi

echo "Install luarocks and dependencies before running this script."
LUA_ROCKS="luarocks-3.12.2.tar.gz"
LUA_ROCKS_DIR="/tmp/luarocks-3.12.2"

downloadTMP "https://luarocks.org/releases/luarocks-3.12.2.tar.gz" "${LUA_ROCKS}"
tarTMP "${LUA_ROCKS}" "/tmp" 

( cd "$LUA_ROCKS_DIR" && ./configure && make && sudo make install )
#sudo luarocks install luasocket 

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

echo -e "=== Installation Complete ===\n"