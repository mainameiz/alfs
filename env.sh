#!/bin/sh


if [ -f ./settings.sh ]; then
	source ./settings.sh
else
	echo "Could not found settings.sh..."
	echo "Terminating..."
	exit 1
fi

set +h
umask 022
LC_ALL=POSIX
MAKEFLAGS="-j1"
# Its good idea to keep it default
LFS_TGT="$(uname -m)-lfs-linux-gnu"
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH MAKEFLAGS