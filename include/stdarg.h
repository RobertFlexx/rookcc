#ifndef _STDARG_H
#define _STDARG_H 1

#ifdef __ROOKCC__
#if defined(__aarch64__) && !defined(__APPLE__)
typedef struct {
    void *__stack;
    void *__gr_top;
    void *__vr_top;
    int __gr_offs;
    int __vr_offs;
} __rcc_va_state;
typedef __rcc_va_state va_list[1];
typedef __rcc_va_state __gnuc_va_list[1];
#elif defined(__riscv) || (defined(__aarch64__) && defined(__APPLE__))
/* The RISC-V and Darwin AArch64 ABIs represent va_list as a cursor. */
typedef void *va_list;
typedef void *__gnuc_va_list;
#else
typedef struct {
    unsigned int gp_offset;
    unsigned int fp_offset;
    void *overflow_arg_area;
    void *reg_save_area;
} __rcc_va_state;
typedef __rcc_va_state va_list[1];
typedef __rcc_va_state __gnuc_va_list[1];
#endif
#else
typedef __builtin_va_list va_list;
typedef __builtin_va_list __gnuc_va_list;
#endif

#define va_start(list, last) __builtin_va_start(list, last)
#define va_arg(list, type) __builtin_va_arg(list, type)
#define va_copy(destination, source) __builtin_va_copy(destination, source)
#define va_end(list) __builtin_va_end(list)

#endif
