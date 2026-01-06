#!/bin/bash
set -e

### -------- CONFIG --------
ORACLE_BASE="/opt/oracle"
ORACLE_HOME="$ORACLE_BASE/product/19.3.0/dbhome_1"
SYSCTL_FILE="/etc/sysctl.d/98-oracle.conf"
LIMITS_FILE="/etc/security/limits.d/oracle-database-preinstall-19c.conf"
ORACLE_DIR="/opt/oracle/product/19.3.0/dbhome_1"
### ------------------------

# -------- Parse arguments --------
while getopts "u:" opt; do
  case $opt in
    u) ORA_USER="$OPTARG" ;;
    *) echo "Usage: $0 [-u oracle_user]" && exit 1 ;;
  esac
done

ORA_USER="${ORA_USER:-$(whoami)}"

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

# -------- Create groups --------
for grp in oinstall dba; do
  if ! getent group "$grp" >/dev/null; then
    groupadd "$grp"
    echo "Created group: $grp"
  fi
done

# -------- Add user to groups --------
usermod -aG oinstall,dba "$ORA_USER"

# -------- sysctl configuration --------
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

# -------- limits.conf --------
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

# -------- Create Oracle home --------
mkdir -p "$ORACLE_DIR"
chown -R "$ORA_USER:oinstall" "$ORACLE_DIR"
chmod -R 775 "$ORACLE_DIR"

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

echo "Oracle 19c system preparation completed successfully."
echo "User $ORA_USER must log out and back in for limits to apply."
