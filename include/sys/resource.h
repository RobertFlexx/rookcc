#ifndef _SYS_RESOURCE_H
#define _SYS_RESOURCE_H 1
#include <rcc/_types.h>
#include <sys/time.h>
typedef unsigned long rlim_t;
struct rlimit { rlim_t rlim_cur; rlim_t rlim_max; };
struct rusage {
    struct timeval ru_utime;
    struct timeval ru_stime;
    long ru_maxrss, ru_ixrss, ru_idrss, ru_isrss;
    long ru_minflt, ru_majflt, ru_nswap, ru_inblock, ru_oublock;
    long ru_msgsnd, ru_msgrcv, ru_nsignals, ru_nvcsw, ru_nivcsw;
};
#define RLIMIT_CPU 0
#define RLIMIT_FSIZE 1
#define RLIMIT_DATA 2
#define RLIMIT_STACK 3
#define RLIMIT_CORE 4
#define RLIMIT_RSS 5
#define RLIMIT_NOFILE 7
#define RLIM_INFINITY (~(rlim_t)0)
#define RUSAGE_SELF 0
#define RUSAGE_CHILDREN (-1)
int getrlimit(int resource, struct rlimit *limits);
int setrlimit(int resource, const struct rlimit *limits);
int getrusage(int who, struct rusage *usage);
#endif
