#!/usr/bin/env bash
# -------------------------------------------------------------------
# update-nvim.sh — Automatically download and install latest Neovim
# Installs to: ~/.local/nvim-linux64
# Symlink:     ~/.local/bin/nvim
# -------------------------------------------------------------------

set -e

echo -e "=== download_nvim.sh ===\n"

# 1️⃣ Variables
NVIM_DIR="/usr/local/nvim"
EXTENSION="tar.gz"

NVIM_ASSET=$(check_architecture)
FILE_NAME="nvim-linux-$NVIM_ASSET"
FILE_NAME_TAR="$FILE_NAME.$EXTENSION"
NVIM_RELEASE_URL="https://github.com/neovim/neovim/releases/latest/download/$FILE_NAME_TAR"

# 2️⃣ Create directories if missing
sudo mkdir -p "$NVIM_DIR" "$LOCAL_BIN"

echo "⬇️  Downloading latest Neovim..."
downloadTMP "$NVIM_RELEASE_URL" "$FILE_NAME_TAR"

echo "📦 Extracting Neovim..."
tarTMP "$FILE_NAME_TAR" "$NVIM_DIR"

if [ -z "$NVIM_DIR" ]; then
	echo "❌ Could not find extracted Neovim directory under $NVIM_DIR"
	exit 1
fi

# 5️⃣ Ensure symlink exists
echo "🔗 Updating symlink..."
EXTRACTED_DIR="$NVIM_DIR/$FILE_NAME"
sudo ln -sf "$EXTRACTED_DIR/bin/nvim" "$LOCAL_BIN/nvim"

# 7️⃣ Verify
echo "✅ Installed Neovim version:"

"$LOCAL_BIN/nvim" --version | head -n 1
echo -e "=== download_nvim.sh complete ===\n"
