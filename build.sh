#!/bin/sh

path=$(dirname $0)

source "$path"/etc/colors.sh
source "$path"/etc/settings.sh
source "$path"/etc/functions.sh
source "$path"/etc/env.sh
clean_sources
clean_logs
exec 7>&1
exec 8>&2

SHELL_PID="$$"

echo -e "${bblack}${white}Constructing a Temporary System${normal}"

BUILDS_DIR="$LFS/alfs/build_tmp_sys"
if [[ ! -d "$BUILDS_DIR" ]]; then
	echo -e "${red}Could not found \"$BUILDS_DIR\" directory${normal}"
	exit 1
fi

LOG_DIR="$LOG_TMP_SYS_DIR"

for build in "$BUILDS_DIR"/*; do
	build_name=$(basename "$build")
	LOG=${build_name%%.xml.sh}
	LOG="$LOG_DIR"/"$LOG".log
	echo -e "${bblack}${yellow}Building: ${lgreen}$build_name${normal}"
	echo -e "${bblack}${yellow}Log: ${white}$LOG${normal}"

	clean_sources
	cd "$LFS/sources"

	touch "$LOG"
	tail -f "$LOG" --pid="$SHELL_PID" &
	PID=$!
	echo "$PID" >> "$LOG_DIR"/tails.pid
	exec 1>> "$LOG"
	exec 2>> "$LOG"
		 
	source "$build" || exit 1

	kill "$PID"
	exec 1>&7
	exec 2>&8

	cd "$LFS/sources"
	clean_sources
done



echo -e "${bblack}${white}Installing Basic System Software${normal}"

BUILDS_DIR="$LFS/alfs/build_sys"
if [[ ! -d "$BUILDS_DIR" ]]; then
	echo -e "${red}Could not found \"$BUILDS_DIR\" directory${normal}"
	exit 1
fi

LOG_DIR="$LOG_SYS_DIR"

for build in "$BUILDS_DIR"/*; do
	build_name=$(basename "$build")
	LOG=${build_name%%.xml.sh}
	LOG="$LOG_DIR"/"$LOG".log
	echo -e "${bblack}${yellow}Building: ${lgreen}$build_name${normal}"
	echo -e "${bblack}${yellow}Log: ${white}$LOG${normal}"

	clean_sources
	cd "$LFS/sources"

	touch "$LOG"
	tail -f "$LOG" --pid="$SHELL_PID" &
	PID=$!
	echo "$PID" >> "$LOG_DIR"/tails.pid
	exec 1>> "$LOG"
	exec 2>> "$LOG"
		 
	source "$build" || exit 1

	kill "$PID"
	exec 1>&7
	exec 2>&8

	cd "$LFS/sources"
	clean_sources
done

echo -e "Well done =)"