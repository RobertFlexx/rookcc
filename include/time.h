#ifndef _TIME_H
#define _TIME_H 1
#include <rcc/features.h>
#include <rcc/_types.h>
#ifndef NULL
#define NULL ((void *)0)
#endif
#define CLOCKS_PER_SEC 1000000L
#define CLOCK_REALTIME 0
#define CLOCK_MONOTONIC 1
#define CLOCK_PROCESS_CPUTIME_ID 2
#define CLOCK_THREAD_CPUTIME_ID 3
#define CLOCK_MONOTONIC_RAW 4
#define CLOCK_REALTIME_COARSE 5
#define CLOCK_MONOTONIC_COARSE 6
#define CLOCK_BOOTTIME 7

typedef int clockid_t;
typedef long clock_t;

#ifndef __RCC_TIMESPEC_DEFINED
#define __RCC_TIMESPEC_DEFINED 1
struct timespec {
    time_t tv_sec;
    long tv_nsec;
};
#endif
struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
    long tm_gmtoff;
    const char *tm_zone;
};
clock_t clock(void);
time_t time(time_t *result);
double difftime(time_t end, time_t beginning);
time_t mktime(struct tm *broken_down);
char *asctime(const struct tm *broken_down);
char *ctime(const time_t *value);
struct tm *gmtime(const time_t *value);
struct tm *localtime(const time_t *value);
struct tm *gmtime_r(const time_t *value, struct tm *result);
struct tm *localtime_r(const time_t *value, struct tm *result);
char *asctime_r(const struct tm *broken_down, char *buffer);
char *ctime_r(const time_t *value, char *buffer);
size_t strftime(char *buffer, size_t maximum, const char *format,
                const struct tm *broken_down);
#ifdef __RCC_USE_POSIX
int clock_gettime(clockid_t clock_id, struct timespec *result);
int clock_settime(clockid_t clock_id, const struct timespec *value);
int clock_getres(clockid_t clock_id, struct timespec *result);
int nanosleep(const struct timespec *request, struct timespec *remaining);
#endif
#endif
