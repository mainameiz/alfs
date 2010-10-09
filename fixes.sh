# To Build Temporary System

# 10-tcl
sed -i -e"s@cd unix@cd tcl8.5.9/unix@" "$LFS/alfs/build_tmp_sys/10-tcl.xml.sh"


# To Install Basic System Software

# 08-glibc
sed -i -e "s@<xxx>@$TIMEZONE@" "$LFS/alfs/build_sys/08-glibc.xml.sh"
# 12-gmp
if [[ ! -z $ABI ]]; then
	sed -i -e "s@./configure@ABI=$ABI ./configure@" "$LFS/alfs/build_sys/12-gmp.xml.sh"
fi
# 42-groff
sed -i -e "s@<paper_size>@$PAGE@" "$LFS/alfs/build_sys/42-groff.xml.sh"
# other fixes

rm -rf "$LFS"/alfs/build_sys/6[1..3]*
# ---