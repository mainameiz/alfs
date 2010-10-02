#!/bin/sh

set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j1"
# It's good idea to keep it default
LFS_TGT="$(uname -m)-lfs-linux-gnu"
PATH="/tools/bin:/bin:/usr/bin"
export LFS LC_ALL LFS_TGT PATH MAKEFLAGS LOG_DIR