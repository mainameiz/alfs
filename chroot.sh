#!/bin/bash

# Use this script to enter the chroot environment then your have finished "Chapter 6. Installing Basic System Software"

source ./etc/settings.sh

mount -v --bind /dev "$LFS"/dev
mount -vt devpts devpts "$LFS"/dev/pts
mount -vt tmpfs shm "$LFS"/dev/shm
mount -vt proc proc "$LFS"/proc
mount -vt sysfs sysfs "$LFS"/sys
    
chroot "$LFS" /usr/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login