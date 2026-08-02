#ifndef _STDIO_H
#define _STDIO_H 1
#include <rcc/features.h>
#include <rcc/capabilities.h>
#include <rcc/_types.h>
#include <stdarg.h>

#define EOF (-1)
#define BUFSIZ 8192
#define FOPEN_MAX 16
#define FILENAME_MAX 4096
#define L_tmpnam 20
#define TMP_MAX 238328
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#define _IOFBF 0
#define _IOLBF 1
#define _IONBF 2
#ifndef NULL
#define NULL ((void *)0)
#endif

typedef struct __rcc_FILE FILE;
typedef long fpos_t;

extern FILE *stdin;
extern FILE *stdout;
extern FILE *stderr;

int remove(const char *path);
int rename(const char *old_path, const char *new_path);
FILE *tmpfile(void);
char *tmpnam(char *buffer);
FILE *fopen(const char *path, const char *mode);
FILE *freopen(const char *path, const char *mode, FILE *stream);
int fclose(FILE *stream);
int fflush(FILE *stream);
void setbuf(FILE *stream, char *buffer);
int setvbuf(FILE *stream, char *buffer, int mode, size_t size);

int fprintf(FILE *stream, const char *format, ...);
int printf(const char *format, ...);
int sprintf(char *buffer, const char *format, ...);
int snprintf(char *buffer, size_t size, const char *format, ...);
int vfprintf(FILE *stream, const char *format, va_list arguments);
int vprintf(const char *format, va_list arguments);
int vsprintf(char *buffer, const char *format, va_list arguments);
int vsnprintf(char *buffer, size_t size, const char *format, va_list arguments);

int fscanf(FILE *stream, const char *format, ...);
int scanf(const char *format, ...);
int sscanf(const char *text, const char *format, ...);

int fgetc(FILE *stream);
char *fgets(char *buffer, int size, FILE *stream);
int fputc(int character, FILE *stream);
int fputs(const char *text, FILE *stream);
int getc(FILE *stream);
int getchar(void);
char *gets(char *buffer);
int putc(int character, FILE *stream);
int putchar(int character);
int puts(const char *text);
int ungetc(int character, FILE *stream);

size_t fread(void *pointer, size_t size, size_t count, FILE *stream);
size_t fwrite(const void *pointer, size_t size, size_t count, FILE *stream);
int fgetpos(FILE *stream, fpos_t *position);
int fseek(FILE *stream, long offset, int origin);
int fsetpos(FILE *stream, const fpos_t *position);
long ftell(FILE *stream);
void rewind(FILE *stream);
void clearerr(FILE *stream);
int feof(FILE *stream);
int ferror(FILE *stream);
void perror(const char *prefix);

#ifdef __RCC_USE_POSIX
FILE *fdopen(int descriptor, const char *mode);
FILE *popen(const char *command, const char *mode);
int pclose(FILE *stream);
int fileno(FILE *stream);
int dprintf(int descriptor, const char *format, ...);
int vdprintf(int descriptor, const char *format, va_list arguments);
char *ctermid(char *buffer);
ssize_t getline(char **line, size_t *capacity, FILE *stream);
ssize_t getdelim(char **line, size_t *capacity, int delimiter, FILE *stream);
#endif

#ifdef __RCC_USE_GNU
int asprintf(char **result, const char *format, ...);
int vasprintf(char **result, const char *format, va_list arguments);
#endif

#endif
