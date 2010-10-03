# unpack tarball and prepare some shell variables
unpack()
{
	tarball=${1##http}
	tarball=${tarball##ftp}
	tarball=${tarball##*\/}

	echo -e "${bblack}${yellow}Unpacking ${lgreen}$tarball${normal}"

	if [[ -e "$tarball" ]]; then
		
		LOG="$LOG_DIR/$tarball.log"
		
		case "$tarball" in
		*.tar.bz2)
			tar xjf "$tarball"
			dir="${tarball%.tar.bz2}"
			if [ $VERBOSE ]; then
				echo "cd \"$dir\"" >> "$LOG"
			fi
			cd "$dir"
			;;
		*.tar.gz)
			tar xzf "$tarball"
			dir="${tarball%.tar.gz}"
			if [ $VERBOSE ]; then
				echo "cd \"$dir\"" >> "$LOG"
			fi
			cd "$dir"
			;;
		*)
			echo "${red}Don't know how to extract '$tarball'${normal}" >> "$LOG"
			exit 1
			;;
		esac
		touch "$LOG"
		echo -e "${bblack}${lgreen}$tarball ${yellow}unpacked${normal}"
	else
		echo -e "${red}'$tarball' is not a valid file!${normal}" >> "$LOG"
		exit 1
	fi
}

clean_sources()
{
	for file in "$LFS"/sources/*; do
		if [ -d "$file" ]; then
			echo -e "${bblack}${yellow}Remove ${lblue}$file ${yellow}directory${normal}"
			rm -rf "$file"
		fi
	done
}