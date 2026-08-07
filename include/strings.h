#ifndef _STRINGS_H
#define _STRINGS_H 1
#include <rcc/_types.h>
int bcmp(const void *left, const void *right, size_t count);
void bcopy(const void *source, void *destination, size_t count);
void bzero(void *destination, size_t count);
int ffs(int value);
int strcasecmp(const char *left, const char *right);
int strncasecmp(const char *left, const char *right, size_t count);
#endif
