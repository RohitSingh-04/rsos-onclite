# RSOS: An Operating System with Vibe (Android 16)
### Custom ROM Architecture for Xiaomi Redmi Y3 (`onclite`)
**Pure Vanilla (No-GApps) | Pre-Rooted (KernelSU) | Embedded Terminal & Linux Micro-Server**
**Target Hardware:** Qualcomm Snapdragon 632 (SDM632), 3 GB RAM, 32 GB Storage

---

## 1. Architectural Blueprint & Technical Breakdown

RSOS is an Android 16 (Baklava) based custom operating system engineered specifically for the Snapdragon 632 platform (`onclite` / `onc`). It blends an ultra-lean footprint, full Linux server capabilities, and a distinct aesthetic identity.

### A. Pure Vanilla (No-GApps) & Storage Efficiency
* **Stock Storage:** 32 GB eMMC 5.1 with standard partitions (`system` ~3.0GB, `vendor` ~1.0GB, `cust` ~800MB).
* **Android 16 Size:** Standard Android 16 system image with Google Play Services exceeds 4.5 GB, causing partition overflow on legacy layouts.
* **Our Implementation:**
  - `WITH_GMS := false` completely strips Google Play Services, Play Store, and Google telemetry.
  - Saves **~850 MB to 1.1 GB of active RAM** and **~3.2 GB of storage**.
  - Retrofitted Dynamic Partitions (`BOARD_SUPER_PARTITION_SIZE := 4294967296`) consolidates `system`, `vendor`, `product`, and `system_ext` inside a 4.0 GB super block.

### B. Pre-Granted Root Engine: KernelSU
* Rather than relying on traditional patching (like Magisk) which modifies ramdisk and triggers SafetyNet/SELinux overhead, **KernelSU** is integrated directly into the kernel source (`kernel/xiaomi/onclite`).
* **Kernel Hook:** Overrides `sys_execve` and `prctl` directly at the kernel driver layer.
* **KernelSU Manager:** Pre-installed as a system package (`KernelSU.apk`) under `/system_ext/priv-app/`.
* Root privileges are granted out-of-the-box to the built-in terminal and background scripts without touching `/system` or compromising OTA integrity.

### C. Pre-Installed Terminal & Full Linux Environment
* **Packages Bundled:**
  - `Termux` (Core Terminal emulator with full apt/dpkg package manager).
  - `Termux:Boot` (Launches background Linux daemons on phone boot).
  - `Termux:API` (Bridges Python and shell scripts to hardware: WiFi, Battery, Cellular, GPS, Camera, Sensors).
  - Native CLI binaries: `bash`, `nano`, `htop`, `curl`, `wget`, `busybox`, `toybox`, `tar`, `gzip`, `strace`, `rsync`.
* **Root Terminal Access:** Executing `su` inside Termux drops immediately into an unrestricted root shell (`uid=0`).

### D. Memory Tuning for 3 GB RAM (Running Python Servers: Django & FastAPI)
Running full Android 16 + GUI + background Python servers on 3 GB RAM would trigger Android's aggressive Low Memory Killer (`lmkd`) and Phantom Process Killer.
* **ZRAM Swap:** 2.5 GB swap initialized on `/dev/block/zram0` with `lz4` compression. Swappiness is set to `100`.
* **Dalvik Heap:** Configured for tight memory footprint:
  ```properties
  dalvik.vm.heapstartsize=8m
  dalvik.vm.heapgrowthlimit=192m
  dalvik.vm.heapsize=384m
  ```
* **LMKD Protection:** Tuned to prevent killing background Python daemon processes.
* **Phantom Process Killer:** Completely disabled via `persist.sys.fflag.override.settings_enable_monitor_phantom_procs=false` and runtime `device_config` tuning.

### E. Hardware Sensor & Driver Matrix (`onclite`)
| Component | Driver / HAL Layer | Status |
| :--- | :--- | :--- |
| **Cellular (4G LTE / VoLTE)** | Qualcomm RIL (`libril-qc-hal-qmi.so`, dual-SIM telephony) | Fully Working |
| **WiFi (802.11 b/g/n)** | Qualcomm WCN3680B (`wlan.ko`, `wpa_supplicant`) | Fully Working |
| **Bluetooth 4.2** | Qualcomm Bluetooth HAL (`bluetooth.default.so`) | Fully Working |
| **Fingerprint** | Goodix (`gf3208`) & FPC (`fpc1020`) Biometric Multihal | Fully Working |
| **Face Unlock** | Android Biometrics Face HAL 1.0 | Fully Working |
| **Gyroscope & Accelerometer** | Qualcomm Sensor Subsystem (`sensors.msm8937.so`) | Fully Working |
| **Proximity & Light** | Qualcomm SSC / SLPI HAL | Fully Working |
| **GPS / GNSS** | Qualcomm GNSS Location Engine (`android.hardware.gnss@2.1`) | Fully Working |
| **IR Blaster** | Consumer IR HAL (`/dev/spidev0.0`) | Fully Working |
| **Cameras** | Rear 12MP+2MP, Front 32MP (`s5kgd1` custom Y3 tuning) | Fully Working |
| **Microphone & Audio** | Qualcomm WCD9326 / PMIC codec, ALSA HAL | Fully Working |

### F. RSOS Custom Boot Animation ("The Vibe")
* **Theme:** OLED pitch-black background with a cyber-luminescent glowing neon `RSOS` logo, a flowing multi-harmonic audio waveform ("Vibe wave"), and subtitle: `AN OPERATING SYSTEM WITH VIBE`.
* **Technical Specifications:**
  - **Resolution:** 720 x 1520 pixels (Native Redmi Y3 19:9 aspect ratio).
  - **Framerate:** 30 FPS.
  - **Part 0 (`part0`):** 45 frames (1.5s intro). Harmonic wave sparks outward, bloom ignites on `RSOS` with cyan/violet neon glow, and tagline fades in smoothly.
  - **Part 1 (`part1`):** 30 frames (1.0s seamless loop). Waveform undulates continuously with mathematical sine-wave loop matching, accompanied by subtle breathing aura on `RSOS`.
  - **Packaging:** Formatted with `ZIP_STORED` (0 compression), including strict trailing newline in `desc.txt`.
  - **Target Location in ROM:** `/product/media/bootanimation.zip`.
  - **Preview & Generator:** Staged at `device_overlay/bootanimation/` with live Python rendering script `generate_bootanimation.py` and animated `preview.gif`.

---

## 2. Compilation Guide (Build Machine Setup)

> [!IMPORTANT]
> Android source code **cannot** be compiled directly on Windows Powershell/CMD because the AOSP build system requires a case-sensitive filesystem (ext4), Linux ELF toolchains, symlinks, and standard POSIX utilities.
>
> You must run the build on **Ubuntu 22.04 LTS / 24.04 LTS** (Dedicated Linux PC, Dual Boot, Cloud Instance like Hetzner/AWS, or WSL2 with ext4).

### System Requirements for Build Machine:
- **OS:** Ubuntu 24.04 LTS or 22.04 LTS (x86_64)
- **CPU:** 4+ Cores (8+ Cores recommended)
- **RAM:** 16 GB minimum (or 8 GB physical RAM + 8 GB Swapfile)
- **Storage:** 150 GB – 250 GB free space on an **ext4** filesystem

> [!WARNING]
> **Disk Space Notice (The 31 GB Limitation):**
> If your system reports `[WARNING] Free disk space is 31GB`, the build will crash halfway through downloading the source tree (`repo sync`).
> - Android 16 source tree alone requires **~45–60 GB** (even with shallow `--depth=1`).
> - Intermediate build artifacts (`out/target/product/onclite/`) require **~60–100 GB**.
> - **Solution:** Connect an external USB 3.0 HDD or SSD formatted as `ext4` with at least 150 GB free space, mount it, and pass the target path directly to the script:
>   ```bash
>   ./build_onclite.sh /media/rohiyaa/<YourDriveName>/android16_workspace
>   ```
> - **Alternative (Cloud / GitHub Actions):** If you don't have enough local disk space, use the included GitHub Actions workflow [`.github/workflows/build_rsos.yml`](file:///c:/Users/rsing/OneDrive/Desktop/onclite/.github/workflows/build_rsos.yml) to compile the ROM on GitHub cloud servers for free.

### Execution Steps:
1. Copy or clone this repository to your Ubuntu machine:
   ```bash
   cd ~/Desktop/onclite
   chmod +x build_onclite.sh
   ./build_onclite.sh
   ```
   *(Or point to an external drive: `./build_onclite.sh /path/to/external/drive/workspace`)*
2. The script will automatically:
   - Handle Ubuntu 24.04 vs 22.04 package differences (`libncurses6` & `libncurses-dev` on 24.04 vs `libncurses5` on 22.04).
   - Install the official Google `repo` binary.
   - Shallow clone LineageOS 22 / Android 16 base tree (`--depth=1`).
   - Sync device, vendor, and kernel trees for `onclite`.
   - Patch the Linux 4.9 kernel with KernelSU.
   - Embed Termux, TermuxBoot, TermuxAPI, and KernelSU Manager APKs.
   - Apply RSOS identity and the custom cyber-neon boot animation.
   - Apply 3 GB RAM Dalvik and LMKD server tuning.
   - Compile the flashable recovery ZIP into `out/target/product/onclite/*.zip`.

---

## 3. Flashing Guide (OrangeFox & TWRP)

### Prerequisites:
- Bootloader must be unlocked (via Mi Flash Unlock Tool).
- Latest **OrangeFox Recovery (R11.1+)** or **TWRP (3.7+)** installed on the device.
- Battery charged to at least 50%.

### Step-by-Step Installation:
1. Copy the generated ROM ZIP (`lineage-22.1-onclite-vanilla.zip`) to an SD Card or USB-OTG drive (or prepare to use `adb sideload`).
2. Boot into Recovery:
   - Power off the phone.
   - Hold **Volume Up + Power** until the recovery logo appears.
3. **Wipe Partitions (Clean Flash):**
   - Go to **Wipe** -> **Advanced Wipe**.
   - Check: `Dalvik / ART Cache`, `Cache`, `System`, `Vendor`, `Data`.
   - Swipe to Wipe.
4. **Format Data:**
   - Go to **Wipe** -> **Format Data**.
   - Type `yes` and confirm (this removes old encryption and prepares the userdata partition).
5. **Flash the ROM ZIP:**
   - Go to **Install**.
   - Select the ROM zip file.
   - Swipe to confirm Flash.
6. **Reboot:**
   - Tap **Reboot System**.
   - First boot will take approximately 3 to 5 minutes.

---

## 4. Running Python Servers (Django & FastAPI) on the Phone

Once booted into Android 16, your phone is ready to function as a Linux micro-server.

### Step 1: Open the Pre-installed Terminal (Termux)
Termux will already be installed on the home screen with full root access pre-configured.

### Step 2: Run the Server Setup Script
In Termux, run:
```bash
# Obtain setup script from /data/local or transfer it
curl -LO https://raw.githubusercontent.com/.../setup_python_server.sh  # or run local copy
chmod +x setup_python_server.sh
./setup_python_server.sh
```
Or manually execute:
```bash
# Acquire wake lock so phone does not enter deep sleep
termux-wake-lock

# Update and install Python + build essentials
pkg update -y
pkg install -y python python-pip clang make git openssh termux-api
pip install fastapi "uvicorn[standard]" django psutil
```

### Step 3: Launch FastAPI Micro-Server
```bash
cd ~/apps/fastapi
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```
Open any web browser on your local network (e.g., from your PC) and navigate to:
```
http://<phone-ip-address>:8000
```
- Interactive API Documentation: `http://<phone-ip-address>:8000/docs`
- Hardware metrics endpoint: `http://<phone-ip-address>:8000/metrics`

### Step 4: Launch Django Server
```bash
cd ~/apps/django
django-admin startproject myserver .
python manage.py migrate
python manage.py runserver 0.0.0.0:8080
```
Access Django at:
```
http://<phone-ip-address>:8080
```

### Step 5: Full Linux Operations via SSH
To manage the device completely headless from your computer terminal:
```bash
# In Termux:
sshd
whoami   # Note your username (e.g. u0_a123)
passwd   # Set your password

# From your PC / Mac terminal:
ssh <username>@<phone-ip-address> -p 8022
```

---

## 5. System File Directory Structure

All configuration and build files created in this project:

```
onclite/
├── RSOS-v1.0-VIBE-onclite-OFFICIAL.zip # Direct Flashable Recovery Installer (OrangeFox / TWRP)
├── create_flashable_zip.py             # Recovery ZIP Packager & Generator Engine
├── BUILD_AND_INSTALL_GUIDE.md          # Complete Technical Architecture & Flashing Guide
├── README.md                           # Quick Navigation & Project Highlights
├── build_onclite.sh                    # Automated Master Compilation Script (for Linux/WSL2 host)
├── generate_bootanimation.py           # RSOS "Vibe" Cyber-Neon Boot Animation Generator
├── local_manifests/
│   └── onclite.xml                     # AOSP Manifest for device, vendor, kernel, & KernelSU
├── device_overlay/
│   ├── BoardConfig.mk                  # HAL flags, Dynamic Partition table, eBPF & KernelSU defines
│   ├── onclite.mk                      # RSOS Identity, Termux packages, 3GB RAM Dalvik/LMKD props
│   ├── init.onclite.server.rc          # ZRAM 2.5GB swap initialization, phantom killer bypass
│   ├── bootanimation/
│   │   ├── bootanimation.zip           # Ready-to-flash uncompressed AOSP boot animation (720x1520)
│   │   ├── desc.txt                    # Animation timing and part sequence descriptor
│   │   ├── preview.gif                 # Animated visual preview
│   │   ├── part0/                      # Intro animation frames
│   │   └── part1/                      # Continuous harmonic looping frames
│   └── prebuilts/
│       └── Android.mk                  # Build rules for Termux, Termux:Boot, Termux:API, KernelSU
└── server_setup/
    ├── setup_python_server.sh          # One-click script to configure Python, FastAPI, Django, SSH
    └── on_boot.sh                      # Init script for background server daemons
```
