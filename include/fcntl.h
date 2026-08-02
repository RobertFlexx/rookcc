#ifndef _FCNTL_H
#define _FCNTL_H 1
#include <rcc/features.h>
#include <rcc/_types.h>
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_CREAT 64
#define O_EXCL 128
#define O_TRUNC 512
#define O_APPEND 1024
#define O_NONBLOCK 2048
#define O_DSYNC 4096
#define O_DIRECT 16384
#define O_DIRECTORY 65536
#define O_NOFOLLOW 131072
#define O_CLOEXEC 524288
int open(const char *path, int flags, ...);
#endif
