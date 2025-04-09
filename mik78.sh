#!/bin/bash

echo "Starting MikroTik CHR 7.15.3 installation..."
sleep 3

# Download CHR image
wget https://github.com/knownrdx/mikrotik/raw/main/chr-7.15.3.img.zip -O chr-7.15.3.img.zip || {
    echo "Download failed!"
    exit 1
}

# Unzip image
unzip chr-7.15.3.img.zip || {
    echo "Unzip failed!"
    exit 1
}

# Identify storage device
STORAGE=$(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" {print $1; exit}')
echo "STORAGE is /dev/$STORAGE"

# Identify main network interface
ETH=$(ip route show default | awk '/default/ {print $5}')
echo "ETH is $ETH"

# Get IP address
ADDRESS=$(ip addr show "$ETH" | grep 'inet ' | awk '{print $2}' | head -n 1)
echo "ADDRESS is $ADDRESS"

# Get gateway
GATEWAY=$(ip route show default | awk '{print $3}')
echo "GATEWAY is $GATEWAY"

sleep 5

# Confirm before flashing
read -p "WARNING: This will erase /dev/$STORAGE. Continue? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Aborted."
    exit 0
fi

# Write image to disk
dd if=chr-7.15.3.img of=/dev/"$STORAGE" bs=4M oflag=sync status=progress || {
    echo "Failed to write image!"
    exit 1
}

echo "Image written successfully. Rebooting in 5 seconds..."
sleep 5

# Force reboot
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger
