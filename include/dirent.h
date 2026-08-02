#ifndef _DIRENT_H
#define _DIRENT_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

#define DT_UNKNOWN 0
#define DT_FIFO 1
#define DT_CHR 2
#define DT_DIR 4
#define DT_BLK 6
#define DT_REG 8
#define DT_LNK 10
#define DT_SOCK 12
#define DT_WHT 14

struct __rcc_DIR;
typedef struct __rcc_DIR DIR;

struct dirent {
    unsigned long d_ino;
    off_t d_off;
    unsigned short d_reclen;
    unsigned char d_type;
    char d_name[256];
};

DIR *opendir(const char *path);
DIR *fdopendir(int fd);
struct dirent *readdir(DIR *directory);
int closedir(DIR *directory);
void rewinddir(DIR *directory);
int dirfd(DIR *directory);

#endif
