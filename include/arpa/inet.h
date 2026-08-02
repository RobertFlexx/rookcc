#ifndef _ARPA_INET_H
#define _ARPA_INET_H 1
#include <netinet/in.h>

in_addr_t inet_addr(const char *text);
char *inet_ntoa(struct in_addr address);
int inet_pton(int family, const char *text, void *address);
const char *inet_ntop(int family, const void *address, char *text,
                      socklen_t size);

#endif
