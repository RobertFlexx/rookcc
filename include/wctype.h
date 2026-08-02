#ifndef _WCTYPE_H
#define _WCTYPE_H 1

#include <wchar.h>

typedef unsigned long wctype_t;
typedef const int *wctrans_t;

int iswalnum(wint_t character);
int iswalpha(wint_t character);
int iswblank(wint_t character);
int iswcntrl(wint_t character);
int iswdigit(wint_t character);
int iswgraph(wint_t character);
int iswlower(wint_t character);
int iswprint(wint_t character);
int iswpunct(wint_t character);
int iswspace(wint_t character);
int iswupper(wint_t character);
int iswxdigit(wint_t character);
wint_t towlower(wint_t character);
wint_t towupper(wint_t character);
wctype_t wctype(const char *property);
int iswctype(wint_t character, wctype_t property);
wctrans_t wctrans(const char *property);
wint_t towctrans(wint_t character, wctrans_t mapping);

#endif
