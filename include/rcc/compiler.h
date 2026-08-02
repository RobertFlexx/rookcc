#ifndef _RCC_COMPILER_H
#define _RCC_COMPILER_H 1

#include <rcc/features.h>
#include <rcc/version.h>
#include <rcc/capabilities.h>

#if defined(__x86_64__)
# define ROOKCC_TARGET_X86_64 1
#elif defined(__aarch64__)
# define ROOKCC_TARGET_AARCH64 1
#elif defined(__riscv) && (__riscv_xlen == 64)
# define ROOKCC_TARGET_RISCV64 1
#endif
#define ROOKCC_TARGET_LINUX 1
#define ROOKCC_POINTER_BITS 64
#define ROOKCC_LITTLE_ENDIAN 1

#ifdef __ROOKCC__
# define ROOKCC_COMPILING 1
#else
# define ROOKCC_COMPILING 0
#endif

#endif
