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

while [ $# -gt 0 ]; do
	case $1 in
	-f|--fetch-book) FETCH_BOOK="y";; # fetch or update existing book
	-h|--help) usage; exit 0;;
	*) echo "$0 -- invalid option '$1'"; usage; exit 0;;
	esac
	shift
done

if [ ! -w $LFS ]; then
	echo -e "${red}You don't have a write permition to $LFS (LFS directory)!${normal}"
	exit 1
fi

echo -e "${yellow}${bblack}Making ${lblue}\"$LFS/tools\"${yellow} directory...${normal}"
mkdir -vp $LFS/tools

if [ -h "/tools" ]; then
	#echo "/tools symlink already exists..."
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
	su root -c"ln -sv $LFS/tools /"
	if [ $? != 0 ]; then
		echo -e "${red}You need root password to continue or make /tools symlink to $LFS/tools yourself${normal}"
		exit 1;
	fi
fi

echo -e "${yellow}${bblack}Making ${lblue}\"$LFS/sources\"${yellow} directory${normal}"
mkdir -vp $LFS/sources
echo

mkdir -p $LFS/alfs/{etc,logs/{tmp_sys,sys}}

OLD_PWD=`pwd`
case $FETCH_BOOK in
	"y")
		if [[ ! -z $BOOK_DIR && -d $BOOK_DIR ]]; then
			echo -e "${bblack}${cyan}Updating book...${normal}"
			cd $BOOK_DIR
			svn update
			cd $OLD_PWD
		else
			echo "Fetch book..."
			svn co svn://svn.linuxfromscratch.org/LFS/trunk/BOOK/
			BOOK_DIR="BOOK"
		fi
	;;
	*)
		if [[ -z "$BOOK_DIR" ]]; then
			echo "Set BOOK_DIR variable in settings.sh or use \"-f\" flag to fetch book!"
			exit 1
		fi
		
		if [[ ! -d $BOOK_DIR ]]; then
			echo -e "\"$BOOK_DIR\" does not exist or not a directory!"
			exit 1
		fi
	;;
esac
echo

cd $BOOK_DIR
make BASEDIR="." wget-list
mv wget-list $OLD_PWD/
cd $OLD_PWD

# Important!
# This commands will remove any files and directories
# which does not exist in "wget-list"
# --- DO NOT PUT YOUR IMPORTANT FILES IN "$LFS/SOURCES"! ---
for file in $LFS/sources/*; do
    file_name=`basename $file`
    found=`grep "$file_name" wget-list`
    if [[ -z "$found" ]]; then
        echo "Remove $file..."
        rm -rf $file
    fi
done
clean_sources
cd $OLD_PWD

FILE_LIST=`cat wget-list`
for URL in $FILE_LIST; do
	FILE=`echo $URL | sed -e"s@\(http\|ftp\)\://.*\/@@"`
	if [ -e $LFS/sources/$FILE ]; then
		if [ $VERBOSE ]; then
			echo "$FILE exists!"
		fi
	else
		echo "$FILE does not exist!"
		cd $LFS/sources
		wget $URL
		cd $OLD_PWD
	fi
done
# ---------------------------

cp settings.sh $LFS/alfs/etc/
cp functions.sh $LFS/alfs/etc/
cp env.sh $LFS/alfs/etc/
cp colors.sh $LFS/alfs/etc/
cp build_tmp_sys.sh $LFS/alfs/
cp build_sys.sh $LFS/alfs/

echo
make parser # Build Parser
echo

rm -rf $LFS/alfs/build_tmp_sys/
#rm -r $LFS/alfs/build_sys/
echo -e "${bblack}${cyan}Parsing Temporary System Scripts${normal}"
./parser $BOOK_DIR/chapter05/chapter05.xml $LFS/alfs/build_tmp_sys/   t
#echo -e "${bblack}${cyan}Parsing LFS System Scripts${normal}"
#./parser $BOOK_DIR/chapter06/chapter06.xml $LFS/alfs/build_sys/       s



rm wget-list