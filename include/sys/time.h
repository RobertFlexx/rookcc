#ifndef _SYS_TIME_H
#define _SYS_TIME_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

struct timeval {
    time_t tv_sec;
    long tv_usec;
};

struct timezone {
    int tz_minuteswest;
    int tz_dsttime;
};

int gettimeofday(struct timeval *time_value, struct timezone *zone);

#endif
