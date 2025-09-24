# Raspberry Pi 5 NAS: SD Boot + SSD Root Setup

This guide helps you configure a Raspberry Pi 5 to boot **firmware/kernel from SD card** while using a **PCIe SATA SSD as the root filesystem**. This setup improves performance and allows for larger root storage.

---

## ⚡ Requirements

- Raspberry Pi 5 (8GB recommended)
- microSD card (512MB+)
- Waveshare PCIe → 2-CH SATA HAT
- 2.5" SATA SSD (one for root filesystem)
- Raspberry Pi OS (Bookworm or newer) flashed to SSD and SD card
- Keyboard + monitor for first setup (optional if SSH works)

---

## 1. Prepare SD Card

1. Flash your SD card using **Raspberry Pi Imager**.
2. In Imager → Advanced Settings:
   - Enable SSH
   - Set a username/password
3. If SD boots with **Raspberry Pi OS Bookworm**, the boot partition may mount at `/boot/firmware` instead of `/boot`.

> Check with:
```bash
ls /boot/firmware/cmdline.txt
```

---

## 2. Prepare SSD Root

1. Attach your SSD via the PCIe HAT.
2. Format and install Raspberry Pi OS on the SSD, or copy your existing root filesystem.
3. Make sure SSD partitions are detected. Run:
```bash
lsblk -f
```
Look for your SSD root partition (e.g., `/dev/sda2`) and note its UUID:
```bash
blkid /dev/sda2
```

---
## 3. Run the Script

1. Save the script:
```bash
nano setup-ssd-root.sh
```
Paste the script and save.
2. Make it executable:
```bash
chmod +x setup-ssd-root.sh
```
3. Run it with sudo:
```bash
sudo ./setup-ssd-root.sh
```
4. Reboot the Pi:
```bash
sudo reboot
```

---

## 4. Verify Boot Setup

```bash
# Root filesystem should be SSD
mount | grep " / "

# Boot partition should be SD card
mount | grep /boot
```

Expected output:
```
/dev/sda2 on / type ext4 ...
/dev/mmcblk0p1 on /boot/firmware type vfat ...
```

Optional: check SSD detection:
```bash
dmesg | grep -i sata
```

---

## 5. SSH Access

- Use the username/password you set in Raspberry Pi Imager.
- If connection is refused:
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## ✅ Notes / Tips

- `/boot/firmware` is used on **Bookworm or newer**; older OS uses `/boot`.
- SSD must be properly formatted and have Raspberry Pi OS installed (or root filesystem copied).  
- Backups of `cmdline.txt` and `fstab` are saved as `.bak` before modification.  
- This setup allows fast SSD root access while keeping SD card as bootloader.
