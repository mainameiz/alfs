#!/bin/sh

source ./settings.sh	# Build Configuration

# Test variables

TMP_USR=`cat /etc/passwd | grep ^$LFS_USER | cut -d':' -f1`
if [[ "x$LFS_USER" != "x$TMP_USR" ]]; then
	echo "User: $LFS_USER not found in /etc/passwd"
	exit 1
fi

OLD_PWD=`pwd`
case $FETCH_BOOK in
	"false")
		if [[ -z "$BOOK_DIR" ]]; then
			echo "Set BOOK_DIR in settings.sh, plz"
			exit 1
		else
			if [[ -e $BOOK_DIR ]]; then
				if [[ ! -d $BOOK_DIR ]]; then
					echo "$BOOK_DIR is not a directory!"
					exit 1
				else
					echo "Fetch book..."
					# обновить книгу
				fi
			else
				echo "$BOOK_DIR does not exist!"
				exit 1
			fi
		fi
	;;
	"true")
		svn co svn://svn.linuxfromscratch.org/LFS/trunk/BOOK/ || echo "Subversion not found" && exit 1
		BOOK_DIR="BOOK"
	;;
	*)
	echo "Could not recognize FETCH_BOOK variable in settings.sh"
	exit 1
	;;
esac

if [[ ! -e $LFS/tools ]]; then
	mkdir -v $LFS/tools
	chown -v $LFS_USER $LFS/tools
fi
	
if [[ -h "/tools" ]]; then
	echo "/tools symlink already exists..."
	TMP_LINK=`readlink -f /tools`
	if [[ "x$TMP_LINK" != "x$LFS/tools" ]]; then
		echo "But does not symlink to $LFS/tools"
		rm -v /tools
		ln -sv $LFS/tools /
	fi
fi

if [[ ! -e $LFS/sources ]]; then
	mkdir -v $LFS/sources
	chown -v $LFS_USER $LFS/sources
fi

su $LFSUSER -c"make" # Build Parser

su $LFS_USER -c"./parser $BOOK_DIR/chapter05/chapter05.xml"

su $LFS_USER -c"xsltproc --xinclude --nonet --output wget-list $BOOK_DIR/stylesheets/wget-list.xsl $BOOK_DIR/chapter03/chapter03.xml"


#sed -e"s@\(http\|ftp\)\://.*\/@@" wget-list > packages

for file in "$LFS/sources/*"; do
    file_name=`basename $file`
    #echo "---"
    echo "$file_name"
    found=`grep "$file_name" wget-list`
    echo $found
    if [[ -z "$found" ]]; then
        echo "Remove $file..."
        rm -v $file
    fi
    #echo $file_name
done

su $LFS_USER -c"cd $LFS/sources && wget -c -i $OLD_PWD/wget-list && cd $OLD_PWD"

#source functions.sh
#env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' ./result.sh