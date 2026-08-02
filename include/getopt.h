#ifndef _GETOPT_H
#define _GETOPT_H 1
#include <rcc/features.h>

#define no_argument 0
#define required_argument 1
#define optional_argument 2

struct option {
    const char *name;
    int has_arg;
    int *flag;
    int val;
};

extern char *optarg;
extern int optind;
extern int opterr;
extern int optopt;

int getopt(int argc, char *const argv[], const char *short_options);
#ifdef __RCC_USE_GNU
int getopt_long(int argc, char *const argv[], const char *short_options,
                const struct option *long_options, int *option_index);
int getopt_long_only(int argc, char *const argv[], const char *short_options,
                     const struct option *long_options, int *option_index);
#endif

#endif
