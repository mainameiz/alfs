#!/bin/sh

source ./etc/functions.sh
source ./etc/env.sh

BUILDS_DIR="$LFS/alfs/build_tmp_sys"
if [[ ! -d $BUILDS_DIR ]]; then
	echo -e "Could not found \"$BUILDS_DIR\" directory"
	exit 1
fi

for build in $BUILDS_DIR/*; do
	build_name=`basename $build`
	echo -e "${bblack}${yellow}Building: ${lgreen}$build_name${normal}"
	log="$LFS/alfs/logs/tmp_sys/$build_name"
	echo -e "${bblack}${yellow}Log: ${white}$log${normal}"
	cd $LFS/sources
	source $build > $log 2>&1 || exit 1
	cd $LFS/sources
done