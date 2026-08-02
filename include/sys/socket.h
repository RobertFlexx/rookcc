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

int socket(int domain, int type, int protocol);
int socketpair(int domain, int type, int protocol, int sockets[2]);
int bind(int socket_fd, const struct sockaddr *address, socklen_t length);
int listen(int socket_fd, int backlog);
int accept(int socket_fd, struct sockaddr *address, socklen_t *length);
int connect(int socket_fd, const struct sockaddr *address, socklen_t length);
ssize_t send(int socket_fd, const void *buffer, size_t length, int flags);
ssize_t recv(int socket_fd, void *buffer, size_t length, int flags);
int shutdown(int socket_fd, int how);

#endif
