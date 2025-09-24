#!/bin/bash
set -euo pipefail

log() { echo -e "\n👉 $1"; }

# Hardcode SSD root partition
SSD_PART="/dev/sda2"
SSD_UUID=$(blkid -s UUID -o value "$SSD_PART" || true)

if [ -z "$SSD_UUID" ]; then
  echo "❌ Could not read UUID for $SSD_PART"
  exit 1
fi
log "✅ Found SSD root partition: $SSD_PART (UUID=$SSD_UUID)"

# Detect boot mountpoint
if [ -d /boot/firmware ]; then
  BOOT_MOUNT="/boot/firmware"
elif [ -d /boot ]; then
  BOOT_MOUNT="/boot"
else
  echo "❌ Could not detect /boot or /boot/firmware"
  exit 1
fi

CMDLINE="$BOOT_MOUNT/cmdline.txt"

if [ ! -f "$CMDLINE" ]; then
  echo "❌ $CMDLINE not found!"
  exit 1
fi

cp "$CMDLINE" "$CMDLINE.bak"
log "📂 Backed up cmdline.txt to $CMDLINE.bak"

sed -i -E "s#root=[^ ]+#root=UUID=$SSD_UUID#" "$CMDLINE"
log "✅ Updated cmdline.txt to use SSD root (UUID=$SSD_UUID)"

# Update /etc/fstab inside SSD rootfs
MOUNTPOINT="/mnt/ssdroot"
mkdir -p "$MOUNTPOINT"
mount "$SSD_PART" "$MOUNTPOINT"

# Get SD boot UUID
SD_BOOT_UUID=$(blkid -s UUID -o value /dev/mmcblk0p1 || true)
if [ -z "$SD_BOOT_UUID" ]; then
  echo "❌ Could not detect SD boot partition UUID"
  exit 1
fi

FSTAB="$MOUNTPOINT/etc/fstab"
if [ -f "$FSTAB" ]; then
  cp "$FSTAB" "$FSTAB.bak"
  log "📂 Backed up fstab to $FSTAB.bak"
fi

cat > "$FSTAB" <<EOF
UUID=$SD_BOOT_UUID  /boot/firmware  vfat   defaults  0  2
UUID=$SSD_UUID      /               ext4   defaults,noatime  0  1
EOF
log "✅ Updated fstab (boot=SD, root=SSD)"

umount "$MOUNTPOINT"
log "🎉 All done! Reboot to test."
