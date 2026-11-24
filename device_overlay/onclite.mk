#
# Copyright (C) 2026 The LineageOS Project
#
# Device Configuration for Xiaomi Redmi Y3 (onclite) - Android 16
# Pure Vanilla (No-GApps), Pre-rooted, Built-in Terminal & Linux Environment
#

# Inherit from common AOSP / Lineage base
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Device identifier & RSOS Identity
PRODUCT_NAME := rsos_onclite
PRODUCT_DEVICE := onclite
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := Redmi Y3
PRODUCT_MANUFACTURER := Xiaomi

# RSOS Branding & Identity Properties
PRODUCT_PROPERTY_OVERRIDES += \
    ro.rsos.version=1.0-VIBE \
    ro.rsos.device=onclite \
    ro.rsos.tagline="An Operating System with Vibe" \
    ro.build.display.id=RSOS-1.0-VIBE-onclite

# Pure Vanilla Build - Strip all GApps, Google Play Services & Telemetry
WITH_GMS := false
TARGET_GAPPS_ARCH := none
PRODUCT_RESTRICT_VENDOR_FILES := false

# Pre-installed Linux Terminal & CLI Utilities
PRODUCT_PACKAGES += \
    Termux \
    TermuxBoot \
    TermuxAPI \
    bash \
    nano \
    htop \
    curl \
    wget \
    busybox \
    toybox \
    strace \
    rsync \
    tar \
    gzip \
    unzip \
    bzip2

# Pre-installed Root Engine (KernelSU Userland Manager + System SU)
PRODUCT_PACKAGES += \
    KernelSU \
    su

# Hardware Sensors & HAL Packages (All sensors active)
PRODUCT_PACKAGES += \
    android.hardware.sensors@2.1-service.multihal \
    android.hardware.biometrics.fingerprint@2.3-service \
    android.hardware.biometrics.face@1.0-service \
    android.hardware.ir-service.example \
    android.hardware.camera.provider@2.4-service \
    android.hardware.gnss@2.1-service-qti \
    android.hardware.wifi@1.0-service \
    android.hardware.bluetooth@1.0-service \
    android.hardware.audio.service \
    android.hardware.lights-service.qti \
    android.hardware.vibrator-service.qti

# Radio / Telephony (RIL & Dual SIM 4G VoLTE)
PRODUCT_PACKAGES += \
    telephony-ext \
    qti-telephony-hidl-wrapper \
    qti_telephony_hidl_wrapper.xml \
    ims-ext-common

# Copy custom init service and RSOS Boot Animation
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init.onclite.server.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.onclite.server.rc \
    $(DEVICE_PATH)/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip

# 3GB RAM / 32GB Storage Tuning Properties
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=192m \
    dalvik.vm.heapsize=384m \
    dalvik.vm.heaptargetutilization=0.75 \
    dalvik.vm.heapminfree=512k \
    dalvik.vm.heapmaxfree=8m \
    ro.config.low_ram=false \
    ro.config.avoid_gfx_accel=false

# LMKD (Low Memory Killer Daemon) Tuning to Protect Python (FastAPI/Django) Server Daemons
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lmk.kill_heaviest_task=false \
    ro.lmk.kill_timeout_ms=100 \
    ro.lmk.use_minfree_levels=false \
    ro.lmk.low=1001 \
    ro.lmk.medium=800 \
    ro.lmk.critical=100 \
    ro.lmk.critical_upgrade=false \
    ro.lmk.upgrade_pressure=100 \
    ro.lmk.downgrade_pressure=100 \
    ro.lmk.thrashing_limit=100 \
    ro.lmk.thrashing_limit_decay=10

# Disable Phantom Process Killer in Android 12+ / 14+ / 16
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.fflag.override.settings_enable_monitor_phantom_procs=false

# WiFi / Cellular / Network Performance
PRODUCT_PROPERTY_OVERRIDES += \
    wifi.interface=wlan0 \
    ro.telephony.default_network=9,9 \
    telephony.lteOnCdmaDevice=1 \
    persist.vendor.radio.data_con_rprt=1 \
    persist.vendor.radio.custom_ecc=1

# Audio & Media Low-Latency Tuning
PRODUCT_PROPERTY_OVERRIDES += \
    vendor.audio.offload.buffer.size.kb=64 \
    audio.deep_buffer.media=true \
    vendor.audio.flac.sw.decoder.24bit=true
