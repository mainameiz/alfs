# Directory of lfs-book. If this variable is empty then lfs-book will be downloaded to "BOOK" directory
BOOK_DIR="$path"/"BOOK"
# LFS root directory
LFS="/home/predator/lfsdir"
VERBOSE="y"
LOG_TMP_SYS_DIR="$LFS/alfs/logs/tmp_sys"
LOG_SYS_DIR="$LFS/alfs/logs/"
CLEAN_LOGS="y"
COMPRESS_TMP_SYS=
# System settings
TIMEZONE="Europe/Moscow"
# If you are building for 32-bit x86, but you have a CPU which is capable of running 64-bit code and you have specified CFLAGS in the environment, the configure script will attempt to configure for 64-bits and fail. Avoid this by setting value of ABI variable to 32
# ABI=32

# Groff expects the environment variable PAGE to contain the default paper size. For users in the United States, PAGE=letter is appropriate. Elsewhere, PAGE=A4 may be more suitable. While the default paper size is configured during compilation, it can be overridden later by echoing either “A4” or “letter” to the /etc/papersize file.
PAGE=a4