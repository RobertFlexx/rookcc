#ifndef _ERRNO_H
#define _ERRNO_H 1
#define EPERM 1
#define ENOENT 2
#define ESRCH 3
#define EINTR 4
#define EIO 5
#define EBADF 9
#define EAGAIN 11
#define ENOMEM 12
#define EACCES 13
#define EFAULT 14
#define EBUSY 16
#define EEXIST 17
#define ENODEV 19
#define ENOTDIR 20
#define EISDIR 21
#define EINVAL 22
#define ENFILE 23
#define EMFILE 24
#define ENOSPC 28
#define EROFS 30
#define EPIPE 32
#define EDOM 33
#define ERANGE 34
#define ENOTSUP 95
#define EOPNOTSUPP ENOTSUP
int *__errno_location(void);
#define errno (*__errno_location())
#endif
