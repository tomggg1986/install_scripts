#!/bin/bash
set -e  
echo "-----------------------------------------------------------------"
echo "--------- Starting Oracle Docker container installation ---------"
echo "-----------------------------------------------------------------"

. "../lib/install_methods.sh"
USER_HOME=$(get_home_dir)
ORACLE_CONTAINER_NAME="oracle19c"
ORACLE_IMAGE_NAME="oracle/database:19.3.0-ee"
ONLY_SQL=true
PATH_TO_ORACLE_ZIP="$HOME/LINUX.X64_193000_db_home.zip"
SKIP_ZIP_PULL=false;

# -------- Parse arguments --------
while getopts "sp:" opt; do
  case $opt in
    p) PATH_TO_ORACLE_ZIP="$OPTARG" ;;
    s) SKIP_ZIP_PULL=true ;;
    *) echo "Usage: $0 [-p oracle_zip_path]" && exit 1 ;;
  esac
done

if [[ "$ONLY_SQL" == false ]]; then
    echo "---------------------------------------------------"
    echo "      Checking for Docker installation..."
    echo "---------------------------------------------------"
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

    echo  -e "---------------------------------------------------"
    echo "      Docker installation check complete."
    echo "---------------------------------------------------"

    if ! $SKIP_ZIP_PULL; then
        echo -e "---------------------------------------------------"
        echo "          Pull Oracle Docker repositpory"
        echo "---------------------------------------------------"
        if [[ -d "$USER_HOME/docker-images" ]]; then
            echo "Removing existing docker-images directory..."
            rm -rf "$USER_HOME/docker-images"
        fi
        echo "Pulling Oracle Docker scripts..."
        git clone https://github.com/oracle/docker-images.git "$USER_HOME/docker-images"

        if [[ -f $PATH_TO_ORACLE_ZIP ]]; then
            cp "$PATH_TO_ORACLE_ZIP" "$USER_HOME/docker-images/OracleDatabase/SingleInstance/dockerfiles/19.3.0/"
        else
            echo "$PATH_TO_ORACLE_ZIP does't exist"
            return 1
        fi
        echo -e "---------------------------------------------------"
        echo "     Pull Oracle Docker repositpory complete"
        echo "---------------------------------------------------"
    fi

    echo -e "---------------------------------------------------"
    echo "              Docker inage creation"
    echo "---------------------------------------------------"
    if ! image_exists "$ORACLE_IMAGE_NAME"; then
        echo "Building Oracle Database Docker image..."
        sudo $USER_HOME/docker-images/OracleDatabase/SingleInstance/dockerfiles/buildContainerImage.sh -v 19.3.0 -e #todo support for other versions
        echo "Oracle Database Docker image built successfully."
    else
        echo "Oracle Database Docker image already exists."
    fi
    echo -e "---------------------------------------------------"
    echo "         Docker inage creation complete"
    echo "---------------------------------------------------"

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
    SQL_SCRIPT="/tmp/pdb_script.sql"


    echo "Creating pluggable database and user..."
    sudo docker cp pdb_script.sql $ORACLE_CONTAINER_NAME:$SQL_SCRIPT
    sudo docker exec -i "$ORACLE_CONTAINER_NAME" sqlplus ${DB_USER}/${DB_PASSWORD}@${PDB_SERVICE} as sysdba @"$SQL_SCRIPT" && echo "Success" || echo "Failed"


else
    echo "Cannot find container $ORACLE_CONTAINER_NAME"
fi


