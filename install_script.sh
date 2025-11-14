#!/bin/bash

set -e

LIB="lib"
LOCAL_BIN="/usr/local/bin"
LOCAL_SRC="/usr/local/src"
LOCAL_INCLUDE="/usr/local/include"

. "$LIB/install_methods.sh"

USER_HOME=$(get_home_dir)
P_MANAGER=$(detect_pkg_manager)

# Store all passed arguments into an array
args=("$@")

declare -A install_actions=(
    [fzf]="$LIB/install_fzf.sh"
    [nvim]="$LIB/download_nvim.sh"
    [nvimLazy]="$LIB/install_nvim.sh"
)

# Ensure required commands are available
check_command git
check_command curl
check_command tar

#Install dependencies
echo -e "=== Installing Dependencies ===\n"

installPackage make
installPackage gcc
installPackage unzip

if [ $# -eq 0 ]; then
    echo "ℹ️ No arguments provided — installing all components..."
    set -- "${!install_actions[@]}"   # Replace args with all keys
fi

for arg in "$@"; do
    if [[ -n "${install_actions[$arg]}" ]]; then
        echo "✅ Found installer for: $arg"
        . ${install_actions[$arg]}
    fi
done