#!/bin/sh

source ./etc/colors.sh
source ./etc/settings.sh
LOG_DIR="$LOG_TMP_SYS_DIR"
source ./etc/functions.sh
source ./etc/env.sh

BUILDS_DIR="$LFS/alfs/build_tmp_sys"
if [[ ! -d "$BUILDS_DIR" ]]; then
	echo -e "${red}Could not found \"$BUILDS_DIR\" directory${normal}"
	exit 1
fi

for build in "$BUILDS_DIR"/*; do
	build_name=$(basename "$build")
	LOG=${build%%.xml.sh}
	LOG=$LOG.log
	echo -e "${bblack}${yellow}Building: ${lgreen}$build_name${normal}"
	echo -e "${bblack}${yellow}Log: ${white}$LOG${normal}"
	clean_sources
	cd "$LFS/sources"
	source "$build" || exit 1
	cd "$LFS/sources"
	clean_sources
done