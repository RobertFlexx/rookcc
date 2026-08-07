#ifndef _SYS_IOCTL_H
#define _SYS_IOCTL_H 1
#include <rcc/_types.h>
int ioctl(int fd, unsigned long request, ...);
#endif
