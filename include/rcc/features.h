#ifndef _RCC_FEATURES_H
#define _RCC_FEATURES_H 1

#define __RCC_HEADER_VERSION__ 101000
#ifdef _GNU_SOURCE
# define __RCC_USE_GNU 1
# define __RCC_USE_MISC 1
# ifndef _DEFAULT_SOURCE
#  define _DEFAULT_SOURCE 1
# endif
# ifndef _POSIX_C_SOURCE
#  define _POSIX_C_SOURCE 200809L
# endif
# ifndef _XOPEN_SOURCE
#  define _XOPEN_SOURCE 700
# endif
#endif

#ifdef _RCC_SOURCE
# define __RCC_USE_RCC 1
# define __RCC_USE_MISC 1
# ifndef _DEFAULT_SOURCE
#  define _DEFAULT_SOURCE 1
# endif
#endif

#ifdef _DEFAULT_SOURCE
# define __RCC_USE_MISC 1
#endif

#ifdef _POSIX_SOURCE
# define __RCC_USE_POSIX 1
#endif

#ifdef _POSIX_C_SOURCE
# define __RCC_USE_POSIX 1
# if _POSIX_C_SOURCE >= 200112L
#  define __RCC_USE_POSIX2001 1
# endif
# if _POSIX_C_SOURCE >= 200809L
#  define __RCC_USE_POSIX2008 1
# endif
#endif

#ifdef _XOPEN_SOURCE
# define __RCC_USE_XOPEN 1
# if _XOPEN_SOURCE >= 700
#  define __RCC_USE_XOPEN700 1
# endif
#endif

#ifndef __RCC_RESTRICT
# define __RCC_RESTRICT restrict
#endif

#define __RCC_BEGIN_DECLS
#define __RCC_END_DECLS
#define __RCC_NORETURN
#define __RCC_UNUSED

#endif
