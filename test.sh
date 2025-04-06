#!/bin/bash
wget https://github.com/knownrdx/mikrotik/blob/main/chr-7.15.3.img.zip -O chr-7.15.3.img.zip && \
gunzip -c chr-7.15.3.img.zip > chr-7.15.3.img.zip && \
mount -o loop,offset=512 chr-7.15.3.img.zip /mnt && \
ADDRESS=`ip addr show ether1 | grep global | cut -d' ' -f 6 | head -n 1` && \
GATEWAY=`ip route list | grep default | cut -d' ' -f 3` && \
echo "/ip address add address=$ADDRESS interface=[/interface ethernet find where name=ether1]
/ip route add gateway=$GATEWAY
/ip service disable telnet
/user set 0 name=root password=ariful"
echo u > /proc/sysrq-trigger && \
dd if=chr-7.15.3.img.zip bs=1024 of=/dev/sda && \
echo "sync disk" && \
echo s > /proc/sysrq-trigger && \
echo "Sleep 5 seconds" && \
sleep 5 && \
echo "Ok, reboot" && \
echo b > /proc/sysrq-trigger​
