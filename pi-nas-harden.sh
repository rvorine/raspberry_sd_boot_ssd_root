#!/bin/bash
set -e

echo "🔒 Pi-NAS Hardening Script"

# --- Detect UUIDs ---
SSD_ROOT_DEV="/dev/sda2"
NAS_DEV="/dev/sdb1"

SSD_UUID=$(blkid -s UUID -o value $SSD_ROOT_DEV)
NAS_UUID=$(blkid -s UUID -o value $NAS_DEV)

echo "✅ SSD root UUID: $SSD_UUID"
echo "✅ NAS disk UUID: $NAS_UUID"

# --- Fix fstab ---
echo "📝 Updating /etc/fstab..."
sudo cp /etc/fstab /etc/fstab.backup.$(date +%F-%H%M)

# Replace root entry
sudo sed -i "s|^UUID=.* / .*|UUID=$SSD_UUID / ext4 defaults,noatime 0 1|" /etc/fstab

# Ensure NAS entry exists
if ! grep -q "$NAS_UUID" /etc/fstab; then
  echo "UUID=$NAS_UUID /srv/dev-disk-by-uuid-$NAS_UUID ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
fi

# --- Fix cmdline.txt ---
CMDLINE="/boot/firmware/cmdline.txt"
echo "📝 Updating $CMDLINE..."
sudo cp $CMDLINE $CMDLINE.backup.$(date +%F-%H%M)
sudo bash -c "echo 'console=serial0,115200 console=tty1 root=$SSD_ROOT_DEV rootfstype=ext4 fsck.repair=yes rootwait rootdelay=5' > $CMDLINE"

# Lock cmdline.txt against accidental overwrite
sudo chattr +i $CMDLINE
echo "✅ Locked $CMDLINE (immutable)."

# --- Ensure PCIe enabled ---
CONFIG="/boot/firmware/config.txt"
if ! grep -q "dtparam=pciex1" $CONFIG; then
  echo -e "\n[all]\ndtparam=pciex1\ndtparam=pciex1_gen=3" | sudo tee -a $CONFIG
  echo "✅ PCIe enabled in $CONFIG"
fi

echo "🎉 Hardening complete. Please reboot to apply changes."
