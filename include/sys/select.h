#ifndef _SYS_SELECT_H
#define _SYS_SELECT_H 1
#include <rcc/_types.h>
#include <signal.h>
#include <sys/time.h>
#include <time.h>

typedef long fd_mask;
#define FD_SETSIZE 1024
#define NFDBITS (8 * (int)sizeof(fd_mask))
typedef struct {
    fd_mask fds_bits[FD_SETSIZE / NFDBITS];
} fd_set;
#define FD_ZERO(set) do { size_t __rcc_fd_i; for (__rcc_fd_i = 0; __rcc_fd_i < (size_t)(FD_SETSIZE / NFDBITS); ++__rcc_fd_i) (set)->fds_bits[__rcc_fd_i] = 0; } while (0)
#define FD_SET(fd,set) ((set)->fds_bits[(fd) / NFDBITS] |= ((fd_mask)1 << ((fd) % NFDBITS)))
#define FD_CLR(fd,set) ((set)->fds_bits[(fd) / NFDBITS] &= ~((fd_mask)1 << ((fd) % NFDBITS)))
#define FD_ISSET(fd,set) (((set)->fds_bits[(fd) / NFDBITS] & ((fd_mask)1 << ((fd) % NFDBITS))) != 0)

int select(int count, fd_set *read_set, fd_set *write_set,
           fd_set *except_set, struct timeval *timeout);
int pselect(int count, fd_set *read_set, fd_set *write_set,
            fd_set *except_set, const struct timespec *timeout,
            const sigset_t *signal_mask);
#endif
