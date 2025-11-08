#!/bin/bash

set -e
LIB="lib"

. "$LIB/install_methods.sh"

USER_HOME=$(get_home_dir)

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



