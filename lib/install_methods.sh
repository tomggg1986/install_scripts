#!/bin/bash

#get_home_dir: Determine the home directory of the current user
get_home_dir() {
    if [ -n "$HOME" ]; then
        echo "$HOME"
    elif [ -n "$SUDO_USER" ]; then
        eval echo "~$SUDO_USER"
    else
        echo "/home/$(whoami)"
    fi
}

#check_command: Verify if a command exists, exit if not found
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed. Please install $1 first."
        exit 1
    fi
}

# Detect architecture and choose appropriate Neovim asset
check_architecture() {
ARCH="$(uname -m)"
case "$ARCH" in
	x86_64|amd64)
		NVIM_ASSET="x86_64"
		;;
	aarch64|arm64)
		NVIM_ASSET="arm64"
		;;
	armv7l|armv7)
		NVIM_ASSET="armv7l"
		;;
	*)
		echo "⚠️  Unknown architecture: $ARCH. Falling back to x86_64 asset."
		NVIM_ASSET="x86_64"
		;;
esac;;
    esac
}