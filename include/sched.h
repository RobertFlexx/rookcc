#ifndef _SCHED_H
#define _SCHED_H 1
#include <rcc/_types.h>
struct sched_param { int sched_priority; };
#define SCHED_OTHER 0
#define SCHED_FIFO 1
#define SCHED_RR 2
int sched_yield(void);
int sched_get_priority_max(int policy);
int sched_get_priority_min(int policy);
int sched_setscheduler(pid_t process, int policy,
                       const struct sched_param *parameter);
int sched_getscheduler(pid_t process);
#endif
