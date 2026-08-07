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

#define CPU_SETSIZE 1024
#define __CPU_BITS (8 * sizeof(unsigned long))
typedef struct {
  unsigned long __bits[(CPU_SETSIZE / __CPU_BITS)];
} cpu_set_t;

#define CPU_ZERO(cpusetp) \
  do { \
    int __cpu_i_; \
    for (__cpu_i_ = 0; __cpu_i_ < (CPU_SETSIZE / __CPU_BITS); ++__cpu_i_) \
      (cpusetp)->__bits[__cpu_i_] = 0; \
  } while (0)
#define CPU_SET(cpu, cpusetp) \
  ((void)((cpusetp)->__bits[(cpu) / __CPU_BITS] |= \
          (1UL << ((cpu) % __CPU_BITS))))

int sched_setaffinity(pid_t pid, size_t cpusetsize, const cpu_set_t *cpuset);
int sched_getaffinity(pid_t pid, size_t cpusetsize, cpu_set_t *cpuset);
#endif
