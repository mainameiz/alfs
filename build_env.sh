#!/bin/sh

usage()
{
	echo "Usage: $cmd_name [OPTION]..."
	echo "  -f, --fetch-book	Fetch book from svn"
	echo "  -v, --verbose		Verbose output"
	echo "  -h, --help		Give this help"
}

cmd_name=$(basename $0)
path=$(readlink -f $(dirname $0))

source "$path"/settings.sh	# Build Configuration
source "$path"/functions.sh	# to clean sources
source "$path"/colors.sh

while [[ $# -gt 0 ]]; do
	case $1 in
	-f|--fetch-book) FETCH_BOOK="y";; # fetch or update existing book
	-v|--verbose) VERBOSE="y";; # verbose output
	-h|--help) usage; exit 0;;
	*) echo "$cmd_name -- invalid option '$1'"; usage; exit 0;;
	esac
	shift
done

case $FETCH_BOOK in
	"y")
		if [[ -z $(command -v svn) ]]; then
			echo -e "${bblack}${red}ERROR: ${cyan}Could not found SVN!${normal}"
			exit 1
		fi
		
		if [[ ! -z "$BOOK_DIR" && -d "$BOOK_DIR" ]]; then
			echo -e "${bblack}${cyan}Updating book...${normal}"
			cd "$BOOK_DIR"
			svn update
			cd "$path"
		else
			echo -e "Fetch book..."
			svn co svn://svn.linuxfromscratch.org/LFS/trunk/BOOK/
			BOOK_DIR="BOOK"
		fi
	;;
	*)
		if [[ -z "$BOOK_DIR" ]]; then
			echo "${bblack}${red}ERROR: ${cyan}Set BOOK_DIR variable in settings.sh or use \"-f\" flag to fetch book!${normal}"
			exit 1
		fi
		
		if [[ ! -d "$BOOK_DIR" ]]; then
			echo -e "${bblack}${red}ERROR: ${lblue}\"$BOOK_DIR\" ${cyan}does not exist or not a directory!${normal}"
			exit 1
		fi
	;;
esac


if [[ ! -w "$LFS" ]]; then
	echo -e "${bblack}${red}You don't have a write permission to $LFS (LFS directory)!${normal}"
	exit 1
fi

echo -e "${bblack}${yellow}Making ${lblue}\"$LFS/tools\"${yellow} directory...${normal}"
mkdir -vp "$LFS/tools"

if [[ -h "/tools" ]]; then
	TMP_LINK=$(readlink -f /tools)
	if [[ "x$TMP_LINK" != "x$LFS/tools" ]]; then
		echo -e "\"/tools\" symlink does not symlink to $LFS/tools"
		su root -c"rm -v /tools; ln -sv $LFS/tools /"
		if [ $? != 0 ]; then
			echo -e "${bblack}${red}You need root password to continue or make /tools symlink to $LFS/tools yourself${normal}"
			exit 1;
		fi
	fi
else
	echo -e "${bblack}${yellow}Making ${lblue}\"/tools\"${yellow} symlink${normal}"
	echo "Give root password:"
	su root -c"ln -sv \"$LFS\"/tools /"
	if [ $? != 0 ]; then
		echo -e "${bblack}${red}You need root password to continue or make /tools symlink to $LFS/tools yourself${normal}"
		exit 1;
	fi
fi

echo -e "${yellow}${bblack}Making ${lblue}\"$LFS/sources\"${yellow} directory${normal}"
mkdir -vp "$LFS/sources"
echo

mkdir -vp "$LFS/alfs/etc"
mkdir -vp "$LOG_TMP_SYS_DIR"
mkdir -vp "$LOG_SYS_DIR"


echo

cd "$BOOK_DIR"
make BASEDIR="." wget-list
mv wget-list "$path"
cd "$path"

# Important!
# These commands will remove any files and directories
# which does not exist in "wget-list"
# --- DO NOT PUT YOUR IMPORTANT FILES IN "$LFS/SOURCES"! ---
echo -e "${bblack}${yellow}Cleaning ${lblue}$LFS/sources ${yellow}directory${normal}"
clean_sources
for file in "$LFS"/sources/*; do
    file_name=$(basename "$file")
    found=$(grep "$file_name" wget-list)
    if [[ -z "$found" ]]; then
        echo -e "${bblack}${yellow}Remove ${lgreen}$file${normal}"
        rm -rf "$file"
    fi
done
echo -e "${bblack}${lblue}$LFS/sources ${yellow}cleaned${normal}"

clean_logs
echo

FILE_LIST=$(cat wget-list)
for URL in $FILE_LIST; do
	FILE=${URL##http}
	FILE=${FILE##ftp}
	FILE=${FILE##*\/}
	if [[ -e "$LFS/sources/$FILE" ]]; then
		if [[ $VERBOSE ]]; then
			echo -e "${bblack}${lblue}$FILE ${yellow}exists!${normal}"
		fi
	else
		echo -e "${bblack}${lblue}$FILE ${yellow}does not exist!${normal}"
			
		if [[ -z $(command -v wget) ]]; then
			echo -e "${bblack}${red}ERROR: ${cyan}Could not found wget!${normal}"
			exit 1
		fi
		
		cd "$LFS/sources"
		
			wget "$URL"
			if [[ ! -e "$LFS/sources/$FILE" ]]; then
				echo -e -n "${bblack}${red}Warning! Failed to download '$FILE'. You can't continue without this file. Try again? ${white}[${lred}yes${white}/${lgreen}no${white}] ${normal}"
				while true; do
					read ANSWER
					case $ANSWER in
						y|yes)
							wget "$URL"
							if [[ -e "$LFS/sources/$FILE" ]]; then
								break
							else
								echo -e -n "${bblack}${red}Warning! Failed to download '$FILE'. You can't continue without this file. Try again? ${white}[${lred}yes${white}/${lgreen}no${white}] ${normal}"
								continue
							fi
						;;
						n|no)
							echo -e "${bblack}${red}To continue, you can...${normal}"
							echo -e "${bblack}${red}1) download this file and paste its into $LFS/sources yourself or ...${normal}"
							echo -e "${bblack}${red}2) try to execute this script again${normal}"
							exit 1
						;;
						*)
						echo -e -n "${bblack}${white}Sorry, response '${cyan}$ANSWER${white}' not understood. [${lred}yes${white}/${lgreen}no${white}] ${normal}"
						;;
					esac
				done
			fi
		
		cd "$path"
	fi
done
unset ANSWER
# ---------------------------

cp -v "$path"/settings.sh "$LFS"/alfs/etc/
cp -v "$path"/functions.sh "$LFS"/alfs/etc/
cp -v "$path"/env.sh "$LFS"/alfs/etc/
cp -v "$path"/colors.sh "$LFS"/alfs/etc/
cp -v "$path"/build.sh "$LFS"/alfs/
cp -v "$path"/fresh.sh "$LFS"/alfs/
cp -v "$path"/chroot.sh "$LFS"/alfs

echo
make -C "$path" parser # Build Parser
echo

rm -rf "$LFS"/alfs/build_tmp_sys/
rm -rf "$LFS"/alfs/build_sys/
echo -e "${bblack}${cyan}Parsing Temporary System Scripts${normal}"
"$path"/parser --verbose --input-file="$BOOK_DIR"/chapter05/chapter05.xml --output-dir="$LFS/alfs/build_tmp_sys/"
echo -e "${bblack}${cyan}Parsing LFS System Scripts${normal}"
"$path"/parser --verbose --include-testing --input-file="$BOOK_DIR"/chapter06/chapter06.xml --output-dir="$LFS/alfs/build_sys/"

source "$path"/fixes.sh

rm wget-list parser