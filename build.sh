#!/bin/sh

if [ -f ./functions.sh ]; then
	source ./functions.sh
else
	echo "Could not found functions.sh..."
	echo "Terminating..."
	exit 1
fi

if [ -f ./env.sh ]; then
	source ./env.sh
else
	echo "Could not found env.sh..."
	echo "Terminating..."
	exit 1
fi

BUILDS_DIR="`pwd`/builds"

for build in $BUILDS_DIR/*; do
	build_name=`basename $build`
	echo -e "Building \"$build_name\"..."
	log="$LOG_DIR/$build_name"
	echo -e "Log -> \"$log\""
	cd $LFS/sources && source $build > $log 2>&1 || exit 1
done