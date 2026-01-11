#!/bin/bash
set -e

while getopts "u:p:" opt; do
  case $opt in
    u) DJ_USER="$OPTARG" ;;
    p) DJ_ZIP_PATH="$OPTARG" ;;
    *) echo "Usage: $0 [-u oracle_user] [-p oracle_zip_path]" && exit 1 ;;
  esac
done

echo "-----------------------------------------------------------------"
echo "----------------- Starting OpenDJ installation ------------------"
echo "-----------------------------------------------------------------"

DJ_USER="${DJ_USER:-$(whoami)}"

export VERSION="$(curl -i -o - --silent https://api.github.com/repos/OpenIdentityPlatform/OpenDJ/releases/latest | grep -m1 "\"name\"" | cut -d\" -f4)" 
echo "last release: $VERSION"
curl -L https://github.com/OpenIdentityPlatform/OpenDJ/releases/download/$VERSION/opendj-$VERSION.zip --output /tmp/opendj.zip
unzip /tmp/opendj.zip -d $DJ_ZIP_PATH
