#ifndef _RCC_H
#define _RCC_H 1

#include <rcc/compiler.h>
#include <rcc/_types.h>

ssize_t read(int fd, void *buffer, size_t count);
ssize_t write(int fd, const void *buffer, size_t count);
int close(int fd);
void exit(int status);
void _Exit(int status);
void abort(void);

size_t strlen(const char *text);
int puts(const char *text);
int putchar(int character);
int getchar(void);
int printf(const char *format, ...);
long print_int(long value);

void *malloc(size_t size);
void *calloc(size_t count, size_t size);
void *realloc(void *pointer, size_t size);
void free(void *pointer);

void *memcpy(void *destination, const void *source, size_t count);
void *memmove(void *destination, const void *source, size_t count);
void *memset(void *destination, int value, size_t count);
int memcmp(const void *left, const void *right, size_t count);

int assert(int condition);
int isdigit(int character);
int isspace(int character);
int isalpha(int character);
int isalnum(int character);
int tolower(int character);
int toupper(int character);

#endif
