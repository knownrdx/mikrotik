#!/bin/bash -e

echo
echo "=== azadrah.org ==="
echo "=== https://github.com/azadrahorg ==="
echo "=== MikroTik 7 Installer ==="
echo
sleep 3
wget https://github.com/knownrdx/mikrotik/blob/main/chr-7.15.3.img.zip -O chr-7.15.3.img.zip  && \
gunzip -c chr-7.15.3.img.zip > chr-7.15.3.img  && \
STORAGE=`lsblk | grep disk | cut -d ' ' -f 1 | head -n 1` && \
echo STORAGE is $STORAGE && \
ETH=`ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p'` && \
echo ETH is $ETH && \
ADDRESS=`ip addr show $ETH | grep global | cut -d' ' -f 6 | head -n 1` && \
echo ADDRESS is $ADDRESS && \
GATEWAY=`ip route list | grep default | cut -d' ' -f 3` && \
echo GATEWAY is $GATEWAY && \
sleep 5 && \
dd if=chr-7.15.3.img of=/dev/$STORAGE bs=4M oflag=sync && \
echo "Ok, reboot" && \
echo 1 > /proc/sys/kernel/sysrq && \
echo b > /proc/sysrq-trigger && \
