#ifndef _ASSERT_H
#define _ASSERT_H 1
#ifdef NDEBUG
#define assert(expression) ((void)0)
#else
int assert(int condition);
#endif
#endif
