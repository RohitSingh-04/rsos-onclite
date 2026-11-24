#!/system/bin/sh
# System-level server daemon startup script for onclite

# Ensure CPU does not go into deep sleep when servers are active
echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Disable Android 12+ Phantom Process Killer
/system/bin/device_config put activity_manager max_phantom_processes 2147483647

# Log boot event
echo "[$(date)] onclite system server boot completed. ZRAM and governors set." >> /data/local/server/logs/boot.log
