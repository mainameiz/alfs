#!/bin/sh

source ./etc/settings.sh
source ./etc/colors.sh

set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j1"
# Its good idea to keep it default
LFS_TGT="$(uname -m)-lfs-linux-gnu"
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH MAKEFLAGS