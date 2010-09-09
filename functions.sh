unpack()
{
	echo "Unpacking $1 in `pwd`"
	tarball=`ls | grep $1*.tar*`
	echo "Find '$tarball'"
	if [ -f $tarball ]; then
		case $tarball in
		*.tar.bz2)
			tar xjf $tarball
			dir=`ls $tarball | sed -e "s|.tar.bz2||g"`
			cd $dir
			;;
		*.tar.gz)
			tar xzf $tarball
			dir=`ls $tarball | sed -e "s|.tar.gz||g"`
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
