#!/bin/bash
set -e  
echo "-----------------------------------------------------------------"
echo "--------- Starting Oracle Docker container installation ---------"
echo "-----------------------------------------------------------------"

. "../lib/install_methods.sh"
USER_HOME=$(get_home_dir)

echo "Checking for Docker installation..."
if ! command -v docker &> /dev/null; then
    read -p "Install Docker? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Docker installation cancelled."
        exit 1
    fi
    DISTRO=$(getDistroID)
    echo "Detected distribution: $DISTRO"
    if [[ "$DISTRO" == "rocky" ]]; then
        echo "Rocky Linux detected. Installing required packages for Docker..."
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin      
    else
        echo "Docker not found. Installing Docker..."
        # Install Docker using the official convenience script
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
else
    echo "Docker is already installed."
fi
echo "Docker installation check complete."

if [[ -d "$USER_HOME/docker-images" ]]; then
    echo "Removing existing docker-images directory..."
    rm -rf "$USER_HOME/docker-images"
fi
echo "Pulling Oracle Docker scripts..."
git clone https://github.com/oracle/docker-images.git "$USER_HOME/docker-images"
echo "Oracle Docker scripts pulled successfully."
echo "Navigating to Oracle Database Dockerfiles directory..."
cd "$USER_HOME/docker-images/OracleDatabase/SingleInstance/dockerfiles"
echo "Current directory: $(pwd)"    
./buildContainerImage.sh -v 19.3.0 -e #todo support for other versions
echo "Oracle Database Docker image built successfully."
