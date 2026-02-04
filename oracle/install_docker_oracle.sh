#!/bin/bash
set -e  
echo "-----------------------------------------------------------------"
echo "--------- Starting Oracle Docker container installation ---------"
echo "-----------------------------------------------------------------"

. "../lib/install_methods.sh"
USER_HOME=$(get_home_dir)
ORACLE_CONTAINER_NAME="oracle19c-sql"
ORACLE_IMAGE_NAME="oracle/database:19.3.0-ee"
ONLY_SQL=true
PATH_TO_ORACLE_ZIP="${1:-$HOME}/LINUX.X64_193000_db_home.zip"

if [[ "$ONLY_SQL" == false ]]; then
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
    cp "$PATH_TO_ORACLE_ZIP" "$USER_HOME/docker-images/OracleDatabase/SingleInstance/dockerfiles/19.3.0/"
    echo "Oracle Docker scripts pulled successfully."
    if ! image_exists "$ORACLE_IMAGE_NAME"; then
        echo "Building Oracle Database Docker image..."
        sudo $USER_HOME/docker-images/OracleDatabase/SingleInstance/dockerfiles/buildContainerImage.sh -v 19.3.0 -e #todo support for other versions
        echo "Oracle Database Docker image built successfully."
    else
        echo "Oracle Database Docker image already exists."
    fi

    echo -e "Creating docker container..."
    sudo docker run -d --name $ORACLE_CONTAINER_NAME -p 1521:1521 -p 5500:5500 -v oracle:/opt/oracle:rw  -e ORACLE_PWD=manager $ORACLE_IMAGE_NAME
    echo "Oracle Database Docker container created and running."
else
    echo "ONLY_SQL is set to true. Skipping Docker installation and Oracle image setup."

fi

# Check if the container is running
if is_container_running "$ORACLE_CONTAINER_NAME"; then
    DB_USER="sys"
    DB_PASSWORD="manager"
    PDB_SERVICE="ORCLCDB"

    echo "Creating pluggable database and user..."
    sudo docker cp pdb_script.sql $ORACLE_CONTAINER_NAME:/tmp/pdb_script.sql
    sudo docker exec -i "$ORACLE_CONTAINER_NAME" bash -c "
    sqlplus -s ${DB_USER}/${DB_PASSWORD}@${PDB_SERVICE} as sysdba <<EOF
    SET ECHO ON
    SET FEEDBACK ON
    SET SERVEROUTPUT ON
    @/tmp/pdb_script.sql
    EXIT
    EOF
    "
fi


