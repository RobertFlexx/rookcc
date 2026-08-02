#ifndef _PTHREAD_H
#define _PTHREAD_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

typedef unsigned long pthread_t;
typedef unsigned int pthread_key_t;
typedef int pthread_once_t;

typedef union { long __data[5]; } pthread_mutex_t;
typedef union { long __data[6]; } pthread_cond_t;
typedef union { long __data[7]; } pthread_rwlock_t;
typedef union { long __data[7]; } pthread_attr_t;
typedef union { long __data[1]; } pthread_mutexattr_t;
typedef union { long __data[1]; } pthread_condattr_t;

#define PTHREAD_ONCE_INIT 0
#define PTHREAD_MUTEX_INITIALIZER { { 0, 0, 0, 0, 0 } }
#define PTHREAD_COND_INITIALIZER  { { 0, 0, 0, 0, 0, 0 } }

int pthread_create(pthread_t *thread, const pthread_attr_t *attributes,
                   void *(*start_routine)(void *), void *argument);
int pthread_join(pthread_t thread, void **result);
int pthread_detach(pthread_t thread);
pthread_t pthread_self(void);
int pthread_equal(pthread_t left, pthread_t right);
void pthread_exit(void *result);

int pthread_mutex_init(pthread_mutex_t *mutex,
                       const pthread_mutexattr_t *attributes);
int pthread_mutex_destroy(pthread_mutex_t *mutex);
int pthread_mutex_lock(pthread_mutex_t *mutex);
int pthread_mutex_trylock(pthread_mutex_t *mutex);
int pthread_mutex_unlock(pthread_mutex_t *mutex);

int pthread_cond_init(pthread_cond_t *condition,
                      const pthread_condattr_t *attributes);
int pthread_cond_destroy(pthread_cond_t *condition);
int pthread_cond_wait(pthread_cond_t *condition, pthread_mutex_t *mutex);
int pthread_cond_signal(pthread_cond_t *condition);
int pthread_cond_broadcast(pthread_cond_t *condition);

#endif
