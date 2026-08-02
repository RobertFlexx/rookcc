#ifndef _POLL_H
#define _POLL_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

typedef unsigned long nfds_t;

struct pollfd {
    int fd;
    short events;
    short revents;
};

#define POLLIN   0x001
#define POLLPRI  0x002
#define POLLOUT  0x004
#define POLLERR  0x008
#define POLLHUP  0x010
#define POLLNVAL 0x020

int poll(struct pollfd *fds, nfds_t count, int timeout_ms);

#endif
