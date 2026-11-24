#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Xiaomi Redmi Y3 (onclite) - Linux Micro-Server & Python Setup Script
# Configures Termux for Django, FastAPI, SSH, and Hardware Sensor Access
# ==============================================================================

set -e

echo "[+] Initializing Linux Environment on Redmi Y3 (onclite)..."

# 1. Acquire CPU Wake Lock to prevent Android from sleeping the CPU
echo "[+] Acquiring Wake Lock..."
termux-wake-lock

# 2. Update Termux Package Repositories
echo "[+] Updating package mirrors..."
pkg update -y && pkg upgrade -y

# 3. Install Core Linux & Development Packages
echo "[+] Installing Core Linux tools, Python, and C compilers..."
pkg install -y \
    python \
    python-pip \
    clang \
    make \
    cmake \
    git \
    openssh \
    curl \
    wget \
    nano \
    htop \
    tree \
    termux-api \
    termux-tools \
    libffi \
    libxml2 \
    libxslt \
    libjpeg-turbo \
    zlib \
    sqlite

# 4. Upgrade pip and install Python Server Frameworks
echo "[+] Installing FastAPI, Uvicorn, Django, and psutil..."
pip install --upgrade pip setuptools wheel
pip install fastapi "uvicorn[standard]" django psutil pydantic requests

# 5. Setup SSH Server for remote terminal access over WiFi/Cellular
echo "[+] Configuring SSH Server on Port 8022..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Generate host keys if not present
ssh-keygen -A
sshd

# Display IP Address
LOCAL_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "127.0.0.1")
echo "[+] SSH Server running on port 8022."
echo "    Connect from PC: ssh $(whoami)@${LOCAL_IP} -p 8022"

# 6. Setup Directory Structure for Web Apps
mkdir -p ~/apps/fastapi
mkdir -p ~/apps/django
mkdir -p ~/.termux/boot

# 7. Create Demo FastAPI Application
cat << 'EOF' > ~/apps/fastapi/main.py
from fastapi import FastAPI
import psutil
import platform
import subprocess
import json

app = FastAPI(title="Redmi Y3 onclite Micro-Server", version="1.0.0")

@app.get("/")
def read_root():
    return {
        "status": "online",
        "device": "Xiaomi Redmi Y3 (onclite)",
        "soc": "Qualcomm Snapdragon 632 (8x Kryo 250)",
        "os": "Android 16 (Baklava) Vanilla KernelSU",
        "architecture": platform.machine()
    }

@app.get("/metrics")
def get_metrics():
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    return {
        "cpu_usage_percent": psutil.cpu_percent(interval=1),
        "ram": {
            "total_mb": mem.total // (1024 * 1024),
            "available_mb": mem.available // (1024 * 1024),
            "used_percent": mem.percent
        },
        "zram_swap": {
            "total_mb": swap.total // (1024 * 1024),
            "used_mb": swap.used // (1024 * 1024),
            "free_mb": swap.free // (1024 * 1024)
        }
    }

@app.get("/hardware/battery")
def get_battery():
    try:
        res = subprocess.check_output(["termux-battery-status"], text=True)
        return json.loads(res)
    except Exception as e:
        return {"error": str(e)}

@app.get("/hardware/wifi")
def get_wifi():
    try:
        res = subprocess.check_output(["termux-wifi-connectioninfo"], text=True)
        return json.loads(res)
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

# 8. Create Boot Auto-Start Script for Termux:Boot
cat << 'EOF' > ~/.termux/boot/start-servers.sh
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sshd
cd ~/apps/fastapi
nohup python -m uvicorn main:app --host 0.0.0.0 --port 8000 > ~/apps/fastapi/fastapi.log 2>&1 &
EOF
chmod +x ~/.termux/boot/start-servers.sh

echo ""
echo "=========================================================================="
echo " [SUCCESS] Linux Micro-Server & Python Environment Ready!"
echo " - Run FastAPI server: cd ~/apps/fastapi && python main.py"
echo " - Test via browser:   http://${LOCAL_IP}:8000"
echo " - SSH into device:    ssh -p 8022 <user>@${LOCAL_IP}"
echo "=========================================================================="
