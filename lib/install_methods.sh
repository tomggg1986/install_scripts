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

is_installed() {
    if command -v "$1" &> /dev/null; then
        return 0  # success
    else
        return 1  # failure
    fi
}

# Detect architecture and choose appropriate Neovim asset
check_architecture() {
   ARCH="$(uname -m)"
   case "$ARCH" in
	x86_64|amd64)
		echo "x86_64"
		;;
	aarch64|arm64)
		echo "arm64"
		;;
	armv7l|armv7)
		NVIM_ASSET="armv7l"
		;;
	*)
		echo "⚠️  Unknown architecture: $ARCH. Falling back to x86_64 asset."
		echo "x86_64"
		;;

    esac
}

#download: Download a file from a URL to a specified location in /tmp
downloadTMP(){
    echo "Downloading $1 to $2"
    curl -L "$1" -o "/tmp/$2"
}

#tarTMP: Extract a tar.gz file from /tmp to a specified directory
tarTMP(){
    echo "Extracting /tmp/$1 to $2"
    sudo chmod +x "/tmp/$1"    
    sudo tar xzf "/tmp/$1" -C "$2"
    # 6️⃣ Clean up
    rm -f "/tmp/$1"
}

# Detect Linux distribution and choose package manager
detect_pkg_manager() {
    distro_id=$(getDistroID)
    case "$distro_id" in
        ubuntu|debian|kali|raspbian)
            pkg_mgr="apt"
            ;;
        fedora)
            pkg_mgr="dnf"
            ;;
        centos|rhel|rocky|almalinux|ol)
            if command -v dnf >/dev/null 2>&1; then
                pkg_mgr="dnf"
            else
                pkg_mgr="yum"
            fi
            ;;
        opensuse*|sles)
            pkg_mgr="zypper"
            ;;
        arch|manjaro|endeavouros)
            pkg_mgr="pacman"
            ;;
        alpine)
            pkg_mgr="apk"
            ;;
        gentoo)
            pkg_mgr="emerge"
            ;;
        void)
            pkg_mgr="xbps-install"
            ;;
        *)
            echo "Unknown distribution: $distro_id"
            return 1
            ;;
    esac

    echo "$pkg_mgr"
    return 0
}

getDistroID() {
    if [[ "$1" == "-v" ]]; then
        show_version=true
    else
        show_version=false
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        distro_id=${ID,,}
        version=${VERSION_ID}
    elif command -v lsb_release >/dev/null 2>&1; then
        distro_id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    else
        echo "Cannot determine Linux distribution."
        return 1
    fi
    
    
    if $show_version; then
        echo "$distro_id$version"
    else
        echo "$distro_id"
    fi

    return 0
}

installPackage(){
    if is_installed $1; then
    echo "$1 is already installed."
else
    echo "Installing $1..."
    sudo $P_MANAGER install -y $1
fi

}

is_container_running(){
    CONTAINER_NAME="$1"

    # Check if container exists (running or stopped)
    if sudo docker ps -a --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
        #echo "Container '$CONTAINER_NAME' exists."
        # Check if it is running
        if sudo docker ps --format '{{.Names}}' | grep -wq "$CONTAINER_NAME"; then
            #echo "Container '$CONTAINER_NAME' is RUNNING."
            return 0
        else
            #echo "Container '$CONTAINER_NAME' exists but is STOPPED."
            return 1
        fi
    else
        #echo "Container '$CONTAINER_NAME' does NOT exist."
        return 1
    fi
}

image_exists() {
    local image_name="$1"
    if sudo docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^${image_name}$"; then
        return 0  # true - image exists
    else
        return 1  # false - image doesn't exist
    fi
}