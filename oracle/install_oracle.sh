#!/bin/bash
set -e

get_group() {
    local input="$1"
    local number_part="${input%%.*}"

    # Validate number
    if [[ ! "$number_part" =~ ^[0-9]+$ ]]; then
        echo "ERROR: '$number_part' is not a valid number" >&2
        exit 1
    fi

    # Compare
    if (( number_part > 19 )); then
        echo "$ORA_USER"
    else
        echo "oinstall" 
    fi
}

# -------- Parse arguments --------
while getopts "u:v:p:" opt; do
  case $opt in
    u) ORA_USER="$OPTARG" ;;
    v) ORA_VERSION="$OPTARG" ;;
    p) ORA_ZIP_PATH="$OPTARG" ;;
    *) echo "Usage: $0 [-u oracle_user] [-v oracle_version] [-p oracle_zip_path]" && exit 1 ;;
  esac
done

### -------- CONFIG --------
BASE_DIR="/opt"
ORACLE_INVERTORY="$BASE_DIR/oraInventory"
ORACLE_BASE="$BASE_DIR/oracle"
ORACLE_HOME="$ORACLE_BASE/product/$ORA_VERSION/dbhome_1"
SYSCTL_FILE="/etc/sysctl.d/98-oracle.conf"
LIMITS_FILE="/etc/security/limits.d/oracle-database-preinstall-19c.conf"
### ------------------------

echo "-----------------------------------------------------------------"
echo "----------- Starting Oracle $ORA_VERSION system preparation -----------"
echo "-----------------------------------------------------------------"


ORA_USER="${ORA_USER:-$(whoami)}"

echo -e "--- Determining Oracle group based on version ---"
ORA_GROUP=$(get_group "$ORA_VERSION")
echo "Using Oracle group: $ORA_GROUP"

if [[ -z "$ORA_VERSION" ]]; then
  echo "Oracle version not specified. Use -v to set the version (e.g., 19.3.0)."
  exit 1
fi

echo "Using Oracle OS user: $ORA_USER"

# -------- Require root --------
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# -------- Ensure user exists --------
if ! id "$ORA_USER" &>/dev/null; then
  echo "User $ORA_USER does not exist"
  exit 1
fi

echo -e "--- Creating required groups oinstall and dba if they do not exist ---"
for grp in oinstall dba; do
  if ! getent group "$grp" >/dev/null; then
    groupadd "$grp"
    echo "Created group: $grp"
  fi
done

echo "--- Adding user $ORA_USER to groups oinstall and dba ---"
usermod -aG oinstall,dba "$ORA_USER"

echo "--- Setting kernel parameters in $SYSCTL_FILE ---"
cat > "$SYSCTL_FILE" <<EOF
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF

/sbin/sysctl -p "$SYSCTL_FILE"

echo "--- Setting user limits in $LIMITS_FILE ---"
cat > "$LIMITS_FILE" <<EOF
# Oracle 19c recommended limits for Linux
# Adapted from oracle-database-preinstall-19c for user $ORA_USER

$ORA_USER   soft    core    0
$ORA_USER   hard    core    0

$ORA_USER   soft    nofile  1024
$ORA_USER   hard    nofile  65536

$ORA_USER   soft    nproc   16384
$ORA_USER   hard    nproc   16384

$ORA_USER   soft    stack   10240
$ORA_USER   hard    stack   32768

$ORA_USER   soft    memlock unlimited
$ORA_USER   hard    memlock unlimited

$ORA_USER   soft    fsize   unlimited
$ORA_USER   hard    fsize   unlimited
EOF

echo "--- Creating Oracle home directory at $ORACLE_HOME ---"
mkdir -p "$ORACLE_HOME"
chown -R "$ORA_USER:$ORA_GROUP" "$ORACLE_BASE"
chmod -R 775 "$ORACLE_BASE"

echo "--- Creating Oracle inventory directory at $ORACLE_INVERTORY ---"
mkdir -p "$ORACLE_INVERTORY"
chown -R "$ORA_USER:$ORA_GROUP" "$ORACLE_INVERTORY"
chmod -R 775 "$ORACLE_INVERTORY"

if [[ -n "$ORA_ZIP_PATH" ]]; then
  echo "--- Unzipping Oracle software from $ORA_ZIP_PATH to $ORACLE_HOME ---"
  su - "$ORA_USER" -c "unzip -oq $ORA_ZIP_PATH -d $ORACLE_HOME"
else
  echo "--- No Oracle zip path provided, skipping unzip step ---"
fi

# -------- Update bashrc --------
BASHRC="/home/$ORA_USER/.bashrc"

grep -q "ORACLE_BASE=" "$BASHRC" || cat >> "$BASHRC" <<EOF

# Oracle 19c environment
export ORACLE_BASE=$ORACLE_BASE
export ORACLE_HOME=\$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_LISTNER=LISTENER
export ORACLE_SID=wind
export ORACLE_COMMANDS=\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$LD_LIBRARY_PATH
export PATH=\$ORACLE_HOME/bin:\$PATH
EOF

echo "--- Fake supported OS version for Oracle installation ---"
export CV_ASSUME_DISTID=RHEL9

echo "---------------------------------------------------------------------"
echo "--- Oracle $ORA_VERSION system preparation completed successfully ---"
echo "---------------------------------------------------------------------"
echo -e "User $ORA_USER must log out and back in for limits to apply !!!"
exit 0
