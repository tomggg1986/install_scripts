#!/usr/bin/env bash
# -------------------------------------------------------------------
# update-nvim.sh — Automatically download and install latest Neovim
# Installs to: ~/.local/nvim-linux64
# Symlink:     ~/.local/bin/nvim
# -------------------------------------------------------------------

set -e

echo "=== download_nvim.sh ==="

# 1️⃣ Variables
NVIM_DIR="/usr/local/nvim"
NVIM_BIN_DIR="$NVIM_DIR/bin"
EXTENSION="tar.gz"

NVIM_ASSET=$(check_architecture)
FILE_NAME="nvim-linux-$NVIM_ASSET.$EXTENSION"
NVIM_RELEASE_URL="https://github.com/neovim/neovim/releases/latest/download/$FILE_NAME"
TMP_TAR="/tmp/$FILE_NAME"

# 2️⃣ Create directories if missing
mkdir -p "$NVIM_DIR" "$NVIM_BIN_DIR"

echo "⬇️  Downloading latest Neovim..."
curl -L "$NVIM_RELEASE_URL" -o "$TMP_TAR"

echo "📦 Extracting Neovim..."
tar xzf "$TMP_TAR" -C "$NVIM_DIR"

if [ -z "$NVIM_DIR" ]; then
	echo "❌ Could not find extracted Neovim directory under $NVIM_DIR"
	exit 1
fi

# 5️⃣ Ensure symlink exists
echo "🔗 Updating symlink..."
EXTRACTED_DIR="$NVIM_DIR/$FILE_NAME"
ln -sf "$EXTRACTED_DIR/bin/nvim" "$NVIM_BIN_DIR/nvim"

# 6️⃣ Clean up
rm -f "$TMP_TAR"

# 7️⃣ Verify
echo "✅ Installed Neovim version:"

"$NVIM_BIN_DIR/nvim" --version | head -n 1
echo "=== download_nvim.sh complete ==="