#!/bin/bash -e

# --- Configuration ---
MIKROTIK_VERSION="7.18.2" # Easier to update version here
IMAGE_URL="https://github.com/elseif/MikroTikPatch/releases/download/${MIKROTIK_VERSION}/chr-${MIKROTIK_VERSION}-legacy-bios.img.zip"
IMAGE_ZIP_FILE="chr-${MIKROTIK_VERSION}-legacy-bios.img.zip"
IMAGE_FILE="chr-${MIKROTIK_VERSION}-legacy-bios.img"

# --- Helper Functions ---
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# --- Main Script ---
echo
log_info "=== azadrah.org ==="
log_info "=== https://github.com/azadrahorg ==="
log_info "=== MikroTik ${MIKROTIK_VERSION} Installer ==="
echo
sleep 3

# Download Image
log_info "Downloading MikroTik CHR image..."
wget -q --show-progress "$IMAGE_URL" -O "$IMAGE_ZIP_FILE" || log_error "Failed to download image."

# Unzip Image
log_info "Unzipping image..."
gunzip -c "$IMAGE_ZIP_FILE" > "$IMAGE_FILE" || log_error "Failed to unzip image."
rm -f "$IMAGE_ZIP_FILE" # Clean up zip file

# --- Network Detection (For Information Only) ---
# Find the primary block device (more robustly)
STORAGE=$(lsblk -ndo NAME,TYPE | awk '/disk/ {print $1; exit}')
if [ -z "$STORAGE" ]; then
    log_error "Could not reliably detect primary storage device."
fi
log_info "Detected target STORAGE device: /dev/$STORAGE"

# Find the default network interface (more robustly)
ETH=$(ip route get 8.8.8.8 | awk -- '{for(i=1; i<=NF; i++) if ($i=="dev") print $(i+1); exit}')
if [ -z "$ETH" ]; then
    log_error "Could not detect default network interface."
fi
log_info "Detected default network interface (in current OS): $ETH"

# Find IPv4 Address/CIDR (more robustly)
ADDRESS=$(ip -4 addr show "$ETH" | grep -oP 'inet \K[\d.]+\/\d+' | head -n 1)
if [ -z "$ADDRESS" ]; then
    log_info "Could not detect IPv4 address for $ETH (maybe IPv6 only or no IP?)."
    # Allow script to continue, maybe user wants manual config anyway
else
    log_info "Detected ADDRESS (in current OS): $ADDRESS"
fi

# Find Default Gateway (more robustly)
GATEWAY=$(ip route show default | grep -oP 'via \K[\d.]+' | head -n 1)
if [ -z "$GATEWAY" ]; then
    log_info "Could not detect default gateway."
    # Allow script to continue
else
    log_info "Detected GATEWAY (in current OS): $GATEWAY"
fi

# --- WARNING ---
echo
log_info "!!! WARNING !!!"
log_info "This script will now COMPLETELY ERASE the disk: /dev/$STORAGE"
log_info "All data on this disk will be PERMANENTLY LOST."
log_info "The detected network settings ($ADDRESS, $GATEWAY) are from the CURRENT OS"
log_info "and WILL NOT be automatically applied to the new MikroTik installation."
log_info "MikroTik will likely use DHCP on its 'ether1' interface or require manual configuration after reboot."
echo
read -p "Type 'YES' to continue, any other input to abort: " CONFIRMATION
if [ "$CONFIRMATION" != "YES" ]; then
    log_info "Aborting installation."
    rm -f "$IMAGE_FILE" # Clean up image file
    exit 0
fi

# Write Image to Disk
log_info "Writing MikroTik image to /dev/$STORAGE... This may take a while."
if dd if="$IMAGE_FILE" of="/dev/$STORAGE" bs=4M oflag=sync status=progress; then
    log_info "Image write successful."
else
    rm -f "$IMAGE_FILE" # Clean up image file
    log_error "dd command failed to write image to /dev/$STORAGE."
fi

# Clean up the image file
rm -f "$IMAGE_FILE"

# Reboot
log_info "Configuration of MikroTik must be done manually or via DHCP after reboot."
log_info "Rebooting system NOW..."
sleep 5
echo 1 > /proc/sys/kernel/sysrq || true # Best effort
echo b > /proc/sysrq-trigger || true # Best effort

# Fallback reboot command if sysrq fails
sync
reboot

exit 0 # Should not be reached if reboot works
