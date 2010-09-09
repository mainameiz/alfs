# Скачивать книгу?
FETCH_BOOK=false

# Директория с книгой, в которую она уже скачана (если FETCH_BOOK=true).
#Или директория, в которую нужно скачать книгу (если FETCH_BOOK=false).
BOOK_DIR=/home/lfs/sources/alfs/BOOK

# От имени какого пользователя собирать систему?
LFS_USER=predator

# Корень будущей системы
LFS=/home/$LFS_USER/lfsdir

# Каталог логов сборки
LOG_DIR="$LFS/lfs_logs"