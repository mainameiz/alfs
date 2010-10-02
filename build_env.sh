#!/bin/sh

source ./settings.sh	# Build Configuration
source ./functions.sh	# to clean sources
source ./colors.sh

usage()
{
	echo "Usage: $0 [OPTION]"
	echo "  -f, --fetch-book	Fetch book from svn"
	echo "  -h, --help		Give this help"
}

while [[ $# -gt 0 ]]; do
	case $1 in
	-f|--fetch-book) FETCH_BOOK="y";; # fetch or update existing book
	-h|--help) usage; exit 0;;
	*) echo "$0 -- invalid option '$1'"; usage; exit 0;;
	esac
	shift
done

OLD_PWD=$(pwd)
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
			cd "$OLD_PWD"
		else
			echo "Fetch book..."
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
	echo -e "${red}You don't have a write permition to $LFS (LFS directory)!${normal}"
	exit 1
fi

echo -e "${yellow}${bblack}Making ${lblue}\"$LFS/tools\"${yellow} directory...${normal}"
mkdir -vp "$LFS/tools"

if [[ -h "/tools" ]]; then
	TMP_LINK=`readlink -f /tools`
	if [[ "x$TMP_LINK" != "x$LFS/tools" ]]; then
		echo -e "\"/tools\" symlink does not symlink to $LFS/tools"
		su root -c"rm -v /tools; ln -sv $LFS/tools /"
		if [ $? != 0 ]; then
			echo -e "${red}You need root password to continue or make /tools symlink to $LFS/tools yourself${normal}"
			exit 1;
		fi
	fi
else
	echo -e "${yellow}${bblack}Making ${lblue}\"/tools\"${yellow} symlink${normal}"
	echo "Give root password:"
	su root -c"ln -sv \"$LFS\"/tools /"
	if [ $? != 0 ]; then
		echo -e "${red}You need root password to continue or make /tools symlink to $LFS/tools yourself${normal}"
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
mv wget-list "$OLD_PWD/"
cd "$OLD_PWD"

# Important!
# These commands will remove any files and directories
# which does not exist in "wget-list"
# --- DO NOT PUT YOUR IMPORTANT FILES IN "$LFS/SOURCES"! ---
echo -e "${bblack}${yellow}Cleaning ${lblue}$LFS/sources ${yellow}directory${normal}"
for file in "$LFS"/sources/*; do
    file_name=$(basename "$file")
    found=$(grep "$file_name" wget-list)
    if [[ -z "$found" ]]; then
        echo -e "${bblack}${yellow}Remove ${lgreen}$file${normal}"
        rm -rf "$file"
    fi
done
clean_sources
echo -e "${bblack}${lblue}$LFS/sources ${yellow}cleaned${normal}"
cd "$OLD_PWD"

if [[ $CLEAN_LOGS ]]; then
	echo -e "${bblack}${yellow}Cleaning logs directories:"
	echo -e "${lblue}$LOG_TMP_SYS_DIR"
	echo -e "$LOG_SYS_DIR${normal}"
	rm -rf "$LOG_TMP_SYS_DIR"/*.log
	rm -rf "$LOG_SYS_DIR"/*.log
	echo -e "${bblack}${yellow}Logs cleaned${normal}"
fi

FILE_LIST=`cat wget-list`
for URL in $FILE_LIST; do
	FILE=${URL##http}
	FILE=${FILE##ftp}
	FILE=${FILE##*\/}
	if [[ -e "$LFS"/sources/"$FILE" ]]; then
		if [[ $VERBOSE ]]; then
			echo "$FILE exists!"
		fi
	else
		echo "$FILE does not exist!"
		cd "$LFS"/sources
		wget "$URL"
		cd "$OLD_PWD"
	fi
done
# ---------------------------

cp settings.sh "$LFS"/alfs/etc/
cp functions.sh "$LFS"/alfs/etc/
cp env.sh "$LFS"/alfs/etc/
cp colors.sh "$LFS"/alfs/etc/
cp build_tmp_sys.sh "$LFS"/alfs/
cp build_sys.sh "$LFS"/alfs/

echo
make parser # Build Parser
echo

rm -rf "$LFS"/alfs/build_tmp_sys/
rm -rf "$LFS"/alfs/build_sys/
echo -e "${bblack}${cyan}Parsing Temporary System Scripts${normal}"
./parser "$BOOK_DIR"/chapter05/chapter05.xml "$LFS"/alfs/build_tmp_sys/   t
#echo -e "${bblack}${cyan}Parsing LFS System Scripts${normal}"
#./parser "$BOOK_DIR"/chapter06/chapter06.xml "$LFS"/alfs/build_sys/       s



rm wget-list parser