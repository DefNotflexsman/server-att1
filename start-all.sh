#!/bin/bash

# =========================================================
# COMPLETE JUPYTER-LAB MINECRAFT + EAGLERCRAFT SETUP
# NO SUDO REQUIRED
# USES CONDA JAVA 17
# RUNS DETACHED (NO NOTEBOOK CRASH)
# INCLUDES:
# - PAPER SERVER
# - PLUGIN SUPPORT
# - PLAYIT.GG TUNNEL
# - EAGLERCRAFT COMPATIBILITY
# - LOW MEMORY OPTIMIZATION
# - AUTO RESTART
# =========================================================

set -e

# =========================================================
# CONFIG
# =========================================================

BASE_DIR="$HOME/eagler-server"
SERVER_DIR="$BASE_DIR/server"
PLUGIN_DIR="$SERVER_DIR/plugins"
LOG_DIR="$BASE_DIR/logs"

mkdir -p "$SERVER_DIR"
mkdir -p "$PLUGIN_DIR"
mkdir -p "$LOG_DIR"

cd "$BASE_DIR"

MC_VERSION="1.20.4"
PAPER_BUILD="499"

MIN_RAM="512M"
MAX_RAM="1G"

SERVER_PORT="25565"

# =========================================================
# INSTALL JAVA 17
# =========================================================

echo "===================================="
echo "INSTALLING JAVA 17 VIA CONDA"
echo "===================================="

conda install -y -c conda-forge openjdk=17

echo "===================================="
echo "JAVA VERSION"
echo "===================================="

java -version

# =========================================================
# DOWNLOAD PAPER SERVER
# =========================================================

echo "===================================="
echo "DOWNLOADING PAPER SERVER"
echo "===================================="

cd "$SERVER_DIR"

wget -O server.jar \
"https://api.papermc.io/v2/projects/paper/versions/$MC_VERSION/builds/$PAPER_BUILD/downloads/paper-$MC_VERSION-$PAPER_BUILD.jar"

# =========================================================
# ACCEPT EULA
# =========================================================

echo "eula=true" > eula.txt

# =========================================================
# OPTIMIZED SERVER.PROPERTIES
# =========================================================

cat > server.properties <<EOF
server-port=$SERVER_PORT
online-mode=false
motd=Jupyter Eaglercraft Server
enable-command-block=true
spawn-protection=0
view-distance=4
simulation-distance=3
network-compression-threshold=512
max-players=10
use-native-transport=false
sync-chunk-writes=false
allow-flight=true
enable-status=true
white-list=false
EOF

# =========================================================
# SPIGOT OPTIMIZATION
# =========================================================

cat > spigot.yml <<EOF
settings:
  save-user-cache-on-stop-only: true
world-settings:
  default:
    merge-radius:
      exp: 4.0
EOF

# =========================================================
# BUKKIT OPTIMIZATION
# =========================================================

cat > bukkit.yml <<EOF
settings:
  allow-end: false
  warn-on-overload: false
EOF

# =========================================================
# PAPER OPTIMIZATION
# =========================================================

mkdir -p config

cat > config/paper-global.yml <<EOF
chunk-loading:
  min-load-radius: 2
messages:
  no-permission: "&cNo permission."
EOF

# =========================================================
# DOWNLOAD ESSENTIAL PLUGINS
# =========================================================

cd "$PLUGIN_DIR"

echo "===================================="
echo "DOWNLOADING PLUGINS"
echo "===================================="

# ViaVersion
wget -O ViaVersion.jar \
https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/5.2.1/PAPER/ViaVersion-5.2.1.jar

# ViaBackwards
wget -O ViaBackwards.jar \
https://hangarcdn.papermc.io/plugins/ViaVersion/ViaBackwards/versions/5.2.1/PAPER/ViaBackwards-5.2.1.jar

# ViaRewind
wget -O ViaRewind.jar \
https://hangarcdn.papermc.io/plugins/ViaVersion/ViaRewind/versions/4.0.3/PAPER/ViaRewind-4.0.3.jar

# Geyser
wget -O Geyser.jar \
https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot

# Floodgate
wget -O Floodgate.jar \
https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot

# =========================================================
# DOWNLOAD PLAYIT.GG
# =========================================================

cd "$BASE_DIR"

echo "===================================="
echo "DOWNLOADING PLAYIT.GG"
echo "===================================="

wget -O playit.tar.gz \
https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64.tar.gz

tar -xzf playit.tar.gz

chmod +x playit

# =========================================================
# SERVER START SCRIPT
# =========================================================

cat > start_server.sh <<EOF
#!/bin/bash

cd "$SERVER_DIR"

while true
do
    java \
    -Xms$MIN_RAM \
    -Xmx$MAX_RAM \
    -XX:+UseG1GC \
    -XX:+ParallelRefProcEnabled \
    -XX:MaxGCPauseMillis=200 \
    -XX:+UnlockExperimentalVMOptions \
    -XX:+DisableExplicitGC \
    -XX:+AlwaysPreTouch \
    -XX:G1HeapRegionSize=8M \
    -XX:G1ReservePercent=20 \
    -XX:InitiatingHeapOccupancyPercent=15 \
    -jar server.jar nogui \
    >> "$LOG_DIR/server.log" 2>&1

    echo "SERVER CRASHED - RESTARTING IN 10 SECONDS"

    sleep 10
done
EOF

chmod +x start_server.sh

# =========================================================
# PLAYIT START SCRIPT
# =========================================================

cat > start_proxy.sh <<EOF
#!/bin/bash

cd "$BASE_DIR"

./playit >> "$LOG_DIR/playit.log" 2>&1
EOF

chmod +x start_proxy.sh

# =========================================================
# START SERVER DETACHED
# =========================================================

echo "===================================="
echo "STARTING SERVER"
echo "===================================="

nohup bash start_server.sh >/dev/null 2>&1 &
echo $! > server.pid

sleep 20

# =========================================================
# START PLAYIT
# =========================================================

echo "===================================="
echo "STARTING PLAYIT"
echo "===================================="

nohup bash start_proxy.sh >/dev/null 2>&1 &
echo $! > proxy.pid

# =========================================================
# DONE
# =========================================================

echo ""
echo "=============================================="
echo "SERVER STARTED"
echo "=============================================="
echo ""
echo "LOGS:"
echo "tail -f $LOG_DIR/server.log"
echo ""
echo "PLAYIT LOGS:"
echo "tail -f $LOG_DIR/playit.log"
echo ""
echo "STOP SERVER:"
echo "kill \$(cat server.pid)"
echo ""
echo "STOP PLAYIT:"
echo "kill \$(cat proxy.pid)"
echo ""
echo "WHEN PLAYIT STARTS IT WILL GIVE A PUBLIC IP"
echo ""
echo "USE THAT IP IN EAGLERCRAFT"
echo ""
echo "=============================================="
