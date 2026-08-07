#ifndef _NETDB_H
#define _NETDB_H 1
#include <sys/socket.h>
#include <rcc/_types.h>
struct hostent {
    char *h_name;
    char **h_aliases;
    int h_addrtype;
    int h_length;
    char **h_addr_list;
};
struct servent {
    char *s_name;
    char **s_aliases;
    int s_port;
    char *s_proto;
};
struct addrinfo {
    int ai_flags;
    int ai_family;
    int ai_socktype;
    int ai_protocol;
    socklen_t ai_addrlen;
    struct sockaddr *ai_addr;
    char *ai_canonname;
    struct addrinfo *ai_next;
};
#define AI_PASSIVE 0x0001
#define AI_CANONNAME 0x0002
#define AI_NUMERICHOST 0x0004
#define AI_NUMERICSERV 0x0400
#define NI_NUMERICHOST 1
#define NI_NUMERICSERV 2
#define EAI_AGAIN (-3)
#define EAI_FAIL (-4)
#define EAI_FAMILY (-6)
#define EAI_MEMORY (-10)
#define EAI_NONAME (-2)
#define EAI_SERVICE (-8)
#define EAI_SOCKTYPE (-7)
struct hostent *gethostbyname(const char *name);
struct hostent *gethostbyaddr(const void *address, socklen_t length, int type);
int getaddrinfo(const char *node, const char *service,
                const struct addrinfo *hints, struct addrinfo **result);
void freeaddrinfo(struct addrinfo *result);
const char *gai_strerror(int error_code);
int getnameinfo(const struct sockaddr *address, socklen_t length,
                char *host, socklen_t host_length,
                char *service, socklen_t service_length, int flags);
#endif
