#ifndef _SYS_SOCKET_H
#define _SYS_SOCKET_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

typedef unsigned int socklen_t;
typedef unsigned short sa_family_t;

struct sockaddr {
    sa_family_t sa_family;
    char sa_data[14];
};

struct sockaddr_storage {
    sa_family_t ss_family;
    char __storage[126];
};

#define SOCK_STREAM 1
#define SOCK_DGRAM 2
#define SOCK_RAW 3
#define SOL_SOCKET 1
#define SO_REUSEADDR 2
#define SO_ERROR 4
#define SO_BROADCAST 6
#define SO_SNDBUF 7
#define SO_RCVBUF 8
#define SO_KEEPALIVE 9
#define SHUT_RD 0
#define SHUT_WR 1
#define SHUT_RDWR 2

int socket(int domain, int type, int protocol);
int socketpair(int domain, int type, int protocol, int sockets[2]);
int bind(int socket_fd, const struct sockaddr *address, socklen_t length);
int listen(int socket_fd, int backlog);
int accept(int socket_fd, struct sockaddr *address, socklen_t *length);
int connect(int socket_fd, const struct sockaddr *address, socklen_t length);
ssize_t send(int socket_fd, const void *buffer, size_t length, int flags);
ssize_t recv(int socket_fd, void *buffer, size_t length, int flags);
ssize_t sendto(int socket_fd, const void *buffer, size_t length, int flags,
               const struct sockaddr *address, socklen_t address_length);
ssize_t recvfrom(int socket_fd, void *buffer, size_t length, int flags,
                 struct sockaddr *address, socklen_t *address_length);
int getsockname(int socket_fd, struct sockaddr *address, socklen_t *length);
int getpeername(int socket_fd, struct sockaddr *address, socklen_t *length);
int getsockopt(int socket_fd, int level, int option, void *value,
               socklen_t *length);
int setsockopt(int socket_fd, int level, int option, const void *value,
               socklen_t length);
int shutdown(int socket_fd, int how);

#endif
