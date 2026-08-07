#ifndef _SEMAPHORE_H
#define _SEMAPHORE_H 1
#include <rcc/_types.h>
#include <fcntl.h>
#include <time.h>
typedef union {
    char __size[32];
    long __align;
} sem_t;
#define SEM_FAILED ((sem_t *)0)
int sem_init(sem_t *semaphore, int shared, unsigned int value);
int sem_destroy(sem_t *semaphore);
sem_t *sem_open(const char *name, int flags, ...);
int sem_close(sem_t *semaphore);
int sem_unlink(const char *name);
int sem_wait(sem_t *semaphore);
int sem_trywait(sem_t *semaphore);
int sem_timedwait(sem_t *semaphore, const struct timespec *timeout);
int sem_post(sem_t *semaphore);
int sem_getvalue(sem_t *semaphore, int *value);
#endif
