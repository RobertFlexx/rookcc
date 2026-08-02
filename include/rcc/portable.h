#ifndef _RCC_PORTABLE_H
#define _RCC_PORTABLE_H 1

#include <rcc/features.h>
#include <rcc/version.h>
#include <rcc/capabilities.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <limits.h>

#if defined(__ROOKCC__)
# define RCC_INLINE inline
# define RCC_NORETURN
# define RCC_UNUSED
# define RCC_RESTRICT restrict
# define RCC_LIKELY(value) (value)
# define RCC_UNLIKELY(value) (value)
#elif defined(__GNUC__) || defined(__clang__)
# define RCC_INLINE inline __attribute__((always_inline))
# define RCC_NORETURN __attribute__((noreturn))
# define RCC_UNUSED __attribute__((unused))
# define RCC_RESTRICT __restrict__
# define RCC_LIKELY(value) __builtin_expect(!!(value), 1)
# define RCC_UNLIKELY(value) __builtin_expect(!!(value), 0)
#else
# define RCC_INLINE inline
# define RCC_NORETURN
# define RCC_UNUSED
# define RCC_RESTRICT
# define RCC_LIKELY(value) (value)
# define RCC_UNLIKELY(value) (value)
#endif

#define RCC_ARRAY_COUNT(array) (sizeof(array) / sizeof((array)[0]))
#define RCC_MIN(left, right) ((left) < (right) ? (left) : (right))
#define RCC_MAX(left, right) ((left) > (right) ? (left) : (right))
#define RCC_CLAMP(value, low, high) \
    (RCC_MIN(RCC_MAX((value), (low)), (high)))

#endif
