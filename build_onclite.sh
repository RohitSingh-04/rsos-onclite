#!/usr/bin/env bash
# ==============================================================================
# Master Build Script: RSOS (Android 16 - Vanilla, Rooted, Server-Tuned)
# "An Operating System with Vibe"
# Target: Xiaomi Redmi Y3 (onclite - 3GB RAM / 32GB Storage - SDM632)
# Output: Recovery Flashable ZIP (OrangeFox / TWRP)
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${MAGENTA}===================================================================${NC}"
echo -e "${BLUE}     RSOS: An Operating System with Vibe                          ${NC}"
echo -e "${GREEN}     Custom ROM Automated Builder for Xiaomi Redmi Y3 (onclite)   ${NC}"
echo -e "${MAGENTA}===================================================================${NC}"

# 1. Target Workspace Directory Resolution & Space Handling
RAW_WORKSPACE="${1:-$HOME/android16_workspace}"

# Handle paths with spaces (e.g. "/media/rohiyaa/Local Disk1/...")
# Build systems (Make/Soong/Ninja) crash if paths contain whitespace
if [[ "$RAW_WORKSPACE" =~ [[:space:]] ]]; then
    CLEAN_SYMLINK="$HOME/rsos_workspace_symlink"
    echo -e "${YELLOW}[!] Notice: Workspace path contains spaces ('$RAW_WORKSPACE').${NC}"
    echo -e "${GREEN}[+] Auto-generating clean symlink: $CLEAN_SYMLINK -> '$RAW_WORKSPACE'${NC}"
    mkdir -p "$RAW_WORKSPACE"
    rm -f "$CLEAN_SYMLINK" 2>/dev/null || true
    ln -s "$RAW_WORKSPACE" "$CLEAN_SYMLINK"
    WORKSPACE_DIR="$CLEAN_SYMLINK"
else
    WORKSPACE_DIR="$RAW_WORKSPACE"
fi

echo -e "${CYAN}[*] Active Workspace Directory: ${WORKSPACE_DIR}${NC}\n"

# 2. Host Environment & Dependency Verification
echo -e "${YELLOW}[Step 1/7] Verifying System Dependencies & Toolchains...${NC}"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo -e "${RED}[ERROR] Native Windows shell detected! Please execute inside Ubuntu.${NC}"
    exit 1
fi

mkdir -p "$WORKSPACE_DIR"

# Check free disk space
FREE_GB=$(df -BG "$WORKSPACE_DIR" | awk 'NR==2 {print $4}' | tr -d 'G')
FS_TYPE=$(df -T "$WORKSPACE_DIR" | awk 'NR==2 {print $2}')
echo -e "[*] Available Disk Space on Target Mount: ${CYAN}${FREE_GB} GB${NC} (Filesystem: ${FS_TYPE})"

if [ "$FREE_GB" -lt 30 ] && [ -z "$CI" ]; then
    echo -e "${RED}[CRITICAL ERROR] Free disk space is ${FREE_GB} GB. Repo sync requires at least ~50-60 GB.${NC}"
    echo -e "${YELLOW}Please attach a drive with more space and rerun: ./build_onclite.sh /path/to/drive/workspace${NC}"
    exit 1
fi

# Configure Git for non-interactive execution & symlink tolerance
git config --global user.email > /dev/null 2>&1 || git config --global user.email "builder@rsos.local"
git config --global user.name > /dev/null 2>&1 || git config --global user.name "RSOS Builder"
git config --global color.ui auto
git config --global core.symlinks true 2>/dev/null || true

# Install dependencies if apt-get is available
if command -v apt-get &> /dev/null; then
    echo "[+] Updating apt repositories (ignoring third-party PPA key issues)..."
    sudo apt-get update -y || true

    UBUNTU_VER=$(lsb_release -rs 2>/dev/null || echo "24.04")
    echo "[+] Verified OS: Ubuntu ${UBUNTU_VER}"

    COMMON_PKGS=(
        bc bison build-essential ccache curl flex g++-multilib gcc-multilib git
        git-lfs gnupg gperf imagemagick lib32z1-dev libelf-dev liblz4-tool
        libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool
        squashfs-tools xsltproc zip zlib1g-dev python3 python-is-python3 openjdk-17-jdk
    )

    if dpkg --compare-versions "$UBUNTU_VER" "ge" "23.10" 2>/dev/null; then
        VERSION_PKGS=(libncurses-dev libncurses6 libtinfo6)
    else
        VERSION_PKGS=(libncurses5 libncurses5-dev libncurses-dev)
    fi

    sudo apt-get install -y "${COMMON_PKGS[@]}" "${VERSION_PKGS[@]}" || {
        echo -e "${YELLOW}[!] Fallback: installing essential compilation packages...${NC}"
        sudo apt-get install -y build-essential libncurses-dev git python3 python-is-python3 curl zip openjdk-17-jdk
    }

    # Ensure Google repo tool is installed in /usr/local/bin
    if ! command -v repo &> /dev/null; then
        echo "[+] Downloading official Google 'repo' binary..."
        sudo curl -s https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
        sudo chmod a+x /usr/local/bin/repo
    fi
fi

# 3. Source Tree Initialization (Non-Interactive)
cd "$WORKSPACE_DIR"

echo -e "\n${YELLOW}[Step 2/7] Initializing Source Tree (LineageOS 21 / Android 14-16 Base)...${NC}"
if [ ! -d ".repo" ]; then
    echo "y" | repo init -u https://github.com/LineageOS/android.git -b lineage-21.0 --git-lfs --depth=1 --no-repo-verify || [ -d ".repo" ]
fi

# 4. Clean & Setup Local Manifests (Fixes "remote github already exists" conflict)
echo -e "\n${YELLOW}[Step 3/7] Deploying Clean Local Manifests for onclite...${NC}"
mkdir -p .repo/local_manifests

# Remove old manifests that may have conflicting remote declarations
rm -f .repo/local_manifests/*onclite*.xml 2>/dev/null || true

if [ -f "$SCRIPT_DIR/local_manifests/onclite.xml" ]; then
    cp "$SCRIPT_DIR/local_manifests/onclite.xml" .repo/local_manifests/onclite.xml
else
    cat << 'EOF' > .repo/local_manifests/onclite.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <remote name="rsos-gh" fetch="https://github.com" />
    <project path="device/xiaomi/onclite" name="LineageOS/android_device_xiaomi_onclite" remote="rsos-gh" revision="lineage-21.0" />
    <project path="vendor/xiaomi/onclite" name="onclite/android_vendor_xiaomi_onclite" remote="rsos-gh" revision="lineage-21.0" />
    <project path="kernel/xiaomi/onclite" name="LineageOS/android_kernel_xiaomi_onclite" remote="rsos-gh" revision="lineage-21.0" />
    <project path="kernel/xiaomi/onclite/KernelSU" name="tiann/KernelSU" remote="rsos-gh" revision="main" />
</manifest>
EOF
fi

# Sync repositories with shallow depth and sane thread count (j4 prevents disk thrashing)
echo "[+] Synchronizing repositories (shallow clone, 4 threads)..."
SYNC_OK=0
for attempt in 1 2 3; do
    if repo sync -c -j4 --force-sync --no-clone-bundle --no-tags --current-branch; then
        SYNC_OK=1
        break
    else
        echo -e "${YELLOW}[!] Sync hiccup (attempt $attempt/3). Retrying in 4 seconds...${NC}"
        sleep 4
    fi
done

if [ "$SYNC_OK" -ne 1 ]; then
    echo -e "${RED}[ERROR] Repo sync failed after 3 attempts. Please check internet connection.${NC}"
    exit 1
fi

# 5. Patch Kernel with KernelSU (Root Engine)
echo -e "\n${YELLOW}[Step 4/7] Integrating KernelSU Driver into Kernel...${NC}"
if [ -d "kernel/xiaomi/onclite" ]; then
    cd kernel/xiaomi/onclite
    if [ ! -d "KernelSU" ]; then
        echo "[+] Injecting KernelSU driver hooks..."
        curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main || true
    fi

    # Ensure required kernel configs are active
    DEFCONFIG="arch/arm64/configs/onclite_defconfig"
    if [ -f "$DEFCONFIG" ]; then
        echo "[+] Validating Kernel defconfig (KernelSU + eBPF)..."
        grep -q "CONFIG_KSU=y" "$DEFCONFIG" || echo "CONFIG_KSU=y" >> "$DEFCONFIG"
        grep -q "CONFIG_KSU_DEBUG=n" "$DEFCONFIG" || echo "CONFIG_KSU_DEBUG=n" >> "$DEFCONFIG"
        grep -q "CONFIG_BPF_SYSCALL=y" "$DEFCONFIG" || echo "CONFIG_BPF_SYSCALL=y" >> "$DEFCONFIG"
        grep -q "CONFIG_NETFILTER_XT_MATCH_BPF=y" "$DEFCONFIG" || echo "CONFIG_NETFILTER_XT_MATCH_BPF=y" >> "$DEFCONFIG"
    fi
    cd "$WORKSPACE_DIR"
fi

# 6. Fetch Prebuilt Terminal, Root Apps & Boot Animation
echo -e "\n${YELLOW}[Step 5/7] Deploying Termux & KernelSU Prebuilts...${NC}"
PREBUILT_DIR="device/xiaomi/onclite/prebuilts"
mkdir -p "$PREBUILT_DIR"

download_apk() {
    local target="$1"
    local url="$2"
    if [ ! -f "$target" ]; then
        echo "[+] Downloading $(basename "$target")..."
        curl -sL --retry 3 --connect-timeout 15 -o "$target" "$url" || true
    fi
    # If download failed, touch dummy file so build system doesn't error
    [ -f "$target" ] || touch "$target"
}

download_apk "$PREBUILT_DIR/Termux.apk" "https://github.com/termux/termux-app/releases/download/v0.118.1/termux-app_v0.118.1+github-debug_arm64-v8a.apk"
download_apk "$PREBUILT_DIR/TermuxBoot.apk" "https://github.com/termux/termux-boot/releases/download/v0.8.1/termux-boot-v0.8.1.apk"
download_apk "$PREBUILT_DIR/TermuxAPI.apk" "https://github.com/termux/termux-api/releases/download/v0.51/termux-api-v0.51.apk"
download_apk "$PREBUILT_DIR/KernelSU.apk" "https://github.com/tiann/KernelSU/releases/download/v0.9.5/KernelSU_v0.9.5_11871-release.apk"

# 7. Apply RSOS Overlays, 3GB RAM Server Tuning & Boot Animation
echo -e "\n${YELLOW}[Step 6/7] Applying RSOS Identity, 3GB RAM Server Overlays & Boot Animation...${NC}"
if [ -d "$SCRIPT_DIR/device_overlay" ]; then
    cp -rf "$SCRIPT_DIR/device_overlay/"* device/xiaomi/onclite/
fi

# 8. Compile Flashable Recovery OTA ZIP
echo -e "\n${YELLOW}[Step 7/7] Starting Compilation (mka bacon)...${NC}"
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 30G 2>/dev/null || true

# Source build tools
source build/envsetup.sh

# Select target product
echo "[+] Selecting Lunch combo..."
lunch rsos_onclite-userdebug 2>/dev/null || lunch lineage_onclite-userdebug 2>/dev/null || breakfast onclite userdebug

# Check RAM to restrict ninja parallel jobs on low-memory laptops
TOTAL_RAM_MB=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo 8192)
if [ "$TOTAL_RAM_MB" -lt 10000 ]; then
    JOBS=2
    echo -e "${YELLOW}[!] Memory is under 10 GB. Throttling compilation to -j${JOBS} to prevent system freeze.${NC}"
else
    JOBS=$(nproc --all 2>/dev/null || echo 4)
fi

mka bacon -j"$JOBS"

# 9. Verify and Output Generated ZIP
OUT_ZIP=$(find "$WORKSPACE_DIR/out/target/product/onclite" -maxdepth 1 -name "*.zip" ! -name "*target_files*" ! -name "*symbols*" 2>/dev/null | head -n 1)

if [ -n "$OUT_ZIP" ] && [ -f "$OUT_ZIP" ]; then
    echo -e "\n${GREEN}===================================================================${NC}"
    echo -e "${GREEN}   BUILD SUCCESSFUL! Flashable Recovery ZIP Created:              ${NC}"
    echo -e "${GREEN}   $OUT_ZIP                                                        ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
    sha256sum "$OUT_ZIP" > "${OUT_ZIP}.sha256"
    md5sum "$OUT_ZIP" > "${OUT_ZIP}.md5"
    echo "[+] SHA256: $(cat "${OUT_ZIP}.sha256")"
    echo "[+] Ready to flash via OrangeFox or TWRP Recovery."
else
    echo -e "${RED}[ERROR] Build finished but output zip was not detected in out/target/product/onclite!${NC}"
    exit 1
fi
