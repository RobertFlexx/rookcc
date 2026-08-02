#ifndef _STDARG_H
#define _STDARG_H 1

#ifdef __ROOKCC__
typedef struct {
    unsigned int gp_offset;
    unsigned int fp_offset;
    void *overflow_arg_area;
    void *reg_save_area;
} __rcc_va_state;
typedef __rcc_va_state va_list[1];
#else
typedef __builtin_va_list va_list;
#endif

#define va_start(list, last) __builtin_va_start(list, last)
#define va_arg(list, type) __builtin_va_arg(list, type)
#define va_copy(destination, source) __builtin_va_copy(destination, source)
#define va_end(list) __builtin_va_end(list)

#endif
