#ifndef _WCHAR_H
#define _WCHAR_H 1

#include <rcc/_types.h>

typedef int wchar_t;
typedef unsigned int wint_t;
typedef struct {
    int __count;
    unsigned int __value;
} mbstate_t;

#define WEOF 0xffffffffU

size_t mbrtowc(wchar_t *wide_character, const char *text, size_t count,
               mbstate_t *state);
size_t wcrtomb(char *text, wchar_t wide_character, mbstate_t *state);
int mbsinit(const mbstate_t *state);
size_t mbsrtowcs(wchar_t *wide_text, const char **text, size_t count,
                 mbstate_t *state);
size_t wcsrtombs(char *text, const wchar_t **wide_text, size_t count,
                 mbstate_t *state);
size_t wcslen(const wchar_t *text);
int wcscmp(const wchar_t *left, const wchar_t *right);
wchar_t *wcscpy(wchar_t *destination, const wchar_t *source);
wchar_t *wcsncpy(wchar_t *destination, const wchar_t *source, size_t count);
wchar_t *wcschr(const wchar_t *text, wchar_t character);
wchar_t *wcsrchr(const wchar_t *text, wchar_t character);
int wcwidth(wchar_t character);
int wcswidth(const wchar_t *text, size_t count);

#endif
