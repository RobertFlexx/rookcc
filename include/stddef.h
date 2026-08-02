#ifndef _STDDEF_H
#define _STDDEF_H 1
#include <rcc/_types.h>
#ifndef NULL
#define NULL 0
#endif
#ifndef offsetof
#define offsetof(type, member) __builtin_offsetof(type, member)
#endif
#endif
