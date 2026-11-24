#
# Copyright (C) 2026 The LineageOS Project
#
# BoardConfig for Xiaomi Redmi Y3 (onclite / onc) - Android 16
# Optimized for 3GB RAM / 32GB Flash, Vanilla No-GApps, Rooted, Micro-Server Capable
#

DEVICE_PATH := device/xiaomi/onclite

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

TARGET_USES_64_BIT_BINDER := true

# Platform
TARGET_BOARD_PLATFORM := msm8953
TARGET_BOARD_PLATFORM_GPU := qcom-adreno506

# Kernel Configuration
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200,n8 earlycon=msm_hsl_uart,0x78af000 androidboot.hardware=qcom
BOARD_KERNEL_CMDLINE += androidboot.console=ttyMSM0 androidboot.memcg=1 service_locator.enable=1
BOARD_KERNEL_CMDLINE += swiotlb=1 loop.max_part=7 androidboot.usbcontroller=78db000.usb
BOARD_KERNEL_CMDLINE += kpti=off androidboot.selinux=permissive
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET := 0x01000000
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_KERNEL_SOURCE := kernel/xiaomi/onclite
TARGET_KERNEL_CONFIG := onclite_defconfig
TARGET_KERNEL_CLANG_COMPILE := true

# KernelSU Integration (In-Kernel Root Engine)
CONFIG_KSU := y

# Retrofitted Dynamic Partitions (Allows Android 16 to fit on 32GB onclite)
BOARD_SUPER_PARTITION_SIZE := 4294967296
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 4290772992
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor product system_ext

# Filesystem / Partition Types
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext

# Display & Graphics (Adreno 506)
TARGET_USES_ION := true
TARGET_USES_NEW_ION_API := true
TARGET_USES_HWC2 := true
TARGET_USES_GRALLOC1 := true
MAX_VIRTUAL_DISPLAY_DIMENSION := 4096

# Audio (Qualcomm MSM8953 / WCD9326 / PMIC)
BOARD_USES_ALSA_AUDIO := true
AUDIO_FEATURE_ENABLED_COMPRESS_VOIP := true
AUDIO_FEATURE_ENABLED_EXTENDED_COMPRESS_FORMAT := true
AUDIO_FEATURE_ENABLED_AAC_ADTS_OFFLOAD := true
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
AUDIO_FEATURE_ENABLED_SSR := true

# Camera (Dual Rear 12MP+2MP, Front 32MP Samsung S5KGD1 for Y3)
TARGET_USES_QTI_CAMERA_DEVICE := true
BOARD_USES_QTI_CAMERA_SERVER := true
TARGET_USES_MEDIA_EXTENSIONS := true
TARGET_CAMERA_OVERRIDE_FORMAT_FROM_RESERVED := true

# Biometrics (Goodix & FPC Fingerprint + Face Unlock)
TARGET_USES_FPC_FINGERPRINT := true
TARGET_USES_GOODIX_FINGERPRINT := true

# Sensors (Qualcomm Sensor Core / SSC / Gyro, Proximity, Light, Compass)
TARGET_USES_NANOHUB_SENSORHAL := false
TARGET_NO_SENSOR_PERMISSION_CHECK := true

# IR Blaster (Consumer IR)
TARGET_PROVIDES_CONSUMERIR_HAL := true

# Connectivity (WiFi & Bluetooth Qualcomm WCN3680B)
BOARD_HAS_QCA_WLAN := true
BOARD_WLAN_DEVICE := qcwcn
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_AP  := "ap"

# Recovery (OrangeFox & TWRP Compatibility)
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
