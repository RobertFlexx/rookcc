#ifndef _RCC_FEATURES_H
#define _RCC_FEATURES_H 1

#define __RCC_HEADER_VERSION__ 400000
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

/* With no feature-test macro selected, and outside strict ISO mode, expose the
   default set the platform headers normally offer. Ordinary programs include
   <unistd.h> and expect the POSIX declarations to be there. */
#if !defined(_GNU_SOURCE) && !defined(_RCC_SOURCE) && \
    !defined(_DEFAULT_SOURCE) && !defined(_POSIX_SOURCE) && \
    !defined(_POSIX_C_SOURCE) && !defined(_XOPEN_SOURCE) && \
    !defined(__STRICT_ANSI__)
# define _DEFAULT_SOURCE 1
#endif

#ifdef _DEFAULT_SOURCE
# define __RCC_USE_MISC 1
# ifndef _POSIX_C_SOURCE
#  define _POSIX_C_SOURCE 200809L
# endif
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
# if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
#  define __RCC_RESTRICT restrict
# elif defined(__RCC_GNU_DIALECT__)
#  define __RCC_RESTRICT __restrict__
# else
#  define __RCC_RESTRICT
# endif
#endif

#define __RCC_BEGIN_DECLS
#define __RCC_END_DECLS
#if defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
# define __RCC_NORETURN _Noreturn
#elif defined(__RCC_GNU_DIALECT__)
# define __RCC_NORETURN __attribute__((noreturn))
#else
# define __RCC_NORETURN
#endif
#if defined(__RCC_GNU_DIALECT__)
# define __RCC_UNUSED __attribute__((unused))
#else
# define __RCC_UNUSED
#endif

#endif
