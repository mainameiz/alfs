unpack()
{
	tarball=`echo $1 | sed -e"s@\(http\|ftp\)\://.*\/@@"`

	if [ -e $tarball ]; then
		case $tarball in
		*.tar.bz2)
			tar xjf $tarball
			dir=`ls $tarball | sed -e "s|.tar.bz2||g"`
			if [ $VERBOSE ]; then
				echo "cd \"$dir\""
			fi
			cd $dir
			;;
		*.tar.gz)
			tar xzf $tarball
			dir=`ls $tarball | sed -e "s|.tar.gz||g"`
			if [ $VERBOSE ]; then
				echo "cd \"$dir\""
			fi
			cd $dir
			;;
		#*.bz2)          bunzip2 $tarball;;
		#*.zip)          unzip $tarball;;
		*)              echo "Don't know how to extract '$tarball'...";;
		esac
	else
		echo "'$tarball' is not a valid file!"
	fi
	#echo $tarball
}

clean_sources()
{
	cd $LFS/sources
	for file in *; do
		if [[ -d $file ]]; then
			echo "Remove $file directory..."
			rm -rf $file
		fi
	done
}