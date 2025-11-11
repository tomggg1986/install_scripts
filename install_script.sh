#!/bin/bash

set -e
LIB="lib"
LOCAL_BIN="/usr/local/bin"
LOCAL_SRC="/usr/local/src"
LOCAL_INCLUDE="/usr/local/include"

. "$LIB/install_methods.sh"

USER_HOME=$(get_home_dir)
P_MANAGER=$(detect_pkg_manager)

#Install dependencies
echo -e "=== Installing Dependencies ===\n"

if is_installed make; then
    echo "make is already installed."
else
    echo "Installing make..."
    sudo $P_MANAGER install -y make
fi

if is_installed gcc; then
    echo "gcc is already installed."
else
    echo "Installing gcc..."
    sudo $P_MANAGER install -y gcc
fi

if is_installed unzip; then
    echo "unzip is already installed."
else
    echo "Installing unzip..."
    sudo $P_MANAGER install -y unzip
fi


# Ensure required commands are available
check_command git
check_command curl
check_command tar

#Install fzf
. "$LIB/install_fzf.sh"

#Install Neovim
. "$LIB/download_nvim.sh"
#Install nvim_config
. "$LIB/install_nvim.sh"



