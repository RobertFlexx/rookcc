#ifndef _NETINET_IN_H
#define _NETINET_IN_H 1
#include <sys/socket.h>
#include <stdint.h>

typedef uint32_t in_addr_t;
typedef uint16_t in_port_t;

struct in_addr {
    in_addr_t s_addr;
};

struct sockaddr_in {
    sa_family_t sin_family;
    in_port_t sin_port;
    struct in_addr sin_addr;
    unsigned char sin_zero[8];
};

#define AF_UNSPEC 0
#define AF_INET 2
#define AF_INET6 10
#define PF_INET AF_INET
#define PF_INET6 AF_INET6
#define INET_ADDRSTRLEN 16
#define INET6_ADDRSTRLEN 46
#define INADDR_ANY ((in_addr_t)0x00000000)
#define INADDR_LOOPBACK ((in_addr_t)0x7f000001)

uint16_t htons(uint16_t value);
uint16_t ntohs(uint16_t value);
uint32_t htonl(uint32_t value);
uint32_t ntohl(uint32_t value);

#endif
