# unpack tarball and prepare some shell variables
unpack()
{
	tarball=${1##http}
	tarball=${tarball##ftp}
	tarball=${tarball##*\/}

	echo ">>> Unpacking $tarball"

	if [[ -e "$tarball" ]]; then
		case "$tarball" in
		*.tar.bz2)
			tar xjf "$tarball"
			dir="${tarball%.tar.bz2}"
			cd "$dir"
			;;
		*.tar.gz)
			tar xzf "$tarball"
			dir="${tarball%.tar.gz}"
			cd "$dir"
			;;
		*)
			echo ">>> Don't know how to extract '$tarball'"
			exit 1
			;;
		esac
		#touch "$LOG"
		echo ">>> $tarball unpacked in $(pwd)"
	else
		echo ">>> '$tarball' is not a valid file!"
		exit 1
	fi
}

clean_sources()
{
	for file in "$LFS"/sources/*; do
		if [ -d "$file" ]; then
			echo -e "${bblack}${lblue}$file ${yellow}removed${normal}"
			rm -rf "$file"
		fi
	done
}

clean_logs()
{
	if [[ $CLEAN_LOGS ]]; then
		echo -e "${bblack}${yellow}Cleaning logs directories:"
		echo -e "${lblue}$LOG_TMP_SYS_DIR"
		echo -e "$LOG_SYS_DIR${normal}"
		rm -rf "$LOG_TMP_SYS_DIR"/*.log
		rm -rf "$LOG_SYS_DIR"/*.log
		echo -e "${bblack}${yellow}Logs cleaned${normal}"
	fi
}