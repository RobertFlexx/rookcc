#ifndef _STDLIB_H
#define _STDLIB_H 1
#include <rcc/features.h>
#include <rcc/_types.h>
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#define RAND_MAX 2147483647
#define MB_CUR_MAX 16
#ifndef NULL
#define NULL ((void *)0)
#endif

typedef struct { int quot; int rem; } div_t;
typedef struct { long quot; long rem; } ldiv_t;
typedef struct { long long quot; long long rem; } lldiv_t;

void *malloc(size_t size);
void *calloc(size_t count, size_t size);
void *realloc(void *pointer, size_t size);
void free(void *pointer);
void exit(int status);
void _Exit(int status);
void abort(void);
int atexit(void (*function)(void));

int atoi(const char *text);
long atol(const char *text);
long long atoll(const char *text);
double atof(const char *text);
long strtol(const char *text, char **end, int base);
unsigned long strtoul(const char *text, char **end, int base);
long long strtoll(const char *text, char **end, int base);
unsigned long long strtoull(const char *text, char **end, int base);
float strtof(const char *text, char **end);
double strtod(const char *text, char **end);
long double strtold(const char *text, char **end);

int rand(void);
void srand(unsigned int seed);
void *bsearch(const void *key, const void *base, size_t count, size_t size,
              int (*compare)(const void *, const void *));
void qsort(void *base, size_t count, size_t size,
           int (*compare)(const void *, const void *));

int abs(int value);
long labs(long value);
long long llabs(long long value);
div_t div(int numerator, int denominator);
ldiv_t ldiv(long numerator, long denominator);
lldiv_t lldiv(long long numerator, long long denominator);

char *getenv(const char *name);
int system(const char *command);

#ifdef __RCC_USE_POSIX2001
int setenv(const char *name, const char *value, int overwrite);
int unsetenv(const char *name);
int putenv(char *assignment);
char *realpath(const char *path, char *resolved);
int mkstemp(char *template_name);
#endif

#ifdef __RCC_USE_GNU
void *reallocarray(void *pointer, size_t count, size_t size);
int getloadavg(double averages[], int count);
char *mkdtemp(char *template_name);
void qsort_r(void *base, size_t count, size_t size,
             int (*compare)(const void *, const void *, void *), void *argument);
#endif

#endif
