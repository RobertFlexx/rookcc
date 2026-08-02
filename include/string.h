#ifndef _STRING_H
#define _STRING_H 1
#include <rcc/features.h>
#include <rcc/_types.h>
void *memcpy(void *destination, const void *source, size_t count);
void *memmove(void *destination, const void *source, size_t count);
void *memset(void *destination, int value, size_t count);
int memcmp(const void *left, const void *right, size_t count);
void *memchr(const void *memory, int character, size_t count);
size_t strlen(const char *text);
int strcmp(const char *left, const char *right);
int strncmp(const char *left, const char *right, size_t count);
int strcoll(const char *left, const char *right);
char *strcpy(char *destination, const char *source);
char *strncpy(char *destination, const char *source, size_t count);
char *strcat(char *destination, const char *source);
char *strncat(char *destination, const char *source, size_t count);
char *strchr(const char *text, int character);
char *strrchr(const char *text, int character);
char *strstr(const char *haystack, const char *needle);
char *strpbrk(const char *text, const char *accept);
size_t strspn(const char *text, const char *accept);
size_t strcspn(const char *text, const char *reject);
char *strtok(char *text, const char *delimiters);
#ifdef __RCC_USE_POSIX
char *strtok_r(char *text, const char *delimiters, char **state);
#endif
size_t strxfrm(char *destination, const char *source, size_t count);
char *strerror(int error_number);
#ifdef __RCC_USE_MISC
size_t strnlen(const char *text, size_t maximum);
char *strdup(const char *text);
char *strndup(const char *text, size_t maximum);
int strcasecmp(const char *left, const char *right);
int strncasecmp(const char *left, const char *right, size_t count);
#endif
#ifdef __RCC_USE_GNU
char *strcasestr(const char *haystack, const char *needle);
void *memrchr(const void *memory, int character, size_t count);
char *strchrnul(const char *text, int character);
#endif
#endif
