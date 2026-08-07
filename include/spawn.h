#ifndef _SPAWN_H
#define _SPAWN_H 1
#include <rcc/_types.h>
#include <sched.h>
#include <signal.h>

struct __spawn_action;
typedef struct {
    short __flags;
    pid_t __pgrp;
    sigset_t __sd;
    sigset_t __ss;
    struct sched_param __sp;
    int __policy;
    int __cgroup;
    int __pad[15];
} posix_spawnattr_t;

typedef struct {
    int __allocated;
    int __used;
    struct __spawn_action *__actions;
    int __pad[16];
} posix_spawn_file_actions_t;

#define POSIX_SPAWN_RESETIDS 0x01
#define POSIX_SPAWN_SETPGROUP 0x02
#define POSIX_SPAWN_SETSIGDEF 0x04
#define POSIX_SPAWN_SETSIGMASK 0x08
#define POSIX_SPAWN_SETSCHEDPARAM 0x10
#define POSIX_SPAWN_SETSCHEDULER 0x20
#define POSIX_SPAWN_USEVFORK 0x40
#define POSIX_SPAWN_SETSID 0x80

int posix_spawn(pid_t *process, const char *path,
                const posix_spawn_file_actions_t *actions,
                const posix_spawnattr_t *attributes,
                char *const arguments[], char *const environment[]);
int posix_spawnp(pid_t *process, const char *file,
                 const posix_spawn_file_actions_t *actions,
                 const posix_spawnattr_t *attributes,
                 char *const arguments[], char *const environment[]);
int posix_spawnattr_init(posix_spawnattr_t *attributes);
int posix_spawnattr_destroy(posix_spawnattr_t *attributes);
int posix_spawnattr_getsigdefault(const posix_spawnattr_t *attributes, sigset_t *set);
int posix_spawnattr_setsigdefault(posix_spawnattr_t *attributes, const sigset_t *set);
int posix_spawnattr_getsigmask(const posix_spawnattr_t *attributes, sigset_t *set);
int posix_spawnattr_setsigmask(posix_spawnattr_t *attributes, const sigset_t *set);
int posix_spawnattr_getflags(const posix_spawnattr_t *attributes, short *flags);
int posix_spawnattr_setflags(posix_spawnattr_t *attributes, short flags);
int posix_spawnattr_getpgroup(const posix_spawnattr_t *attributes, pid_t *group);
int posix_spawnattr_setpgroup(posix_spawnattr_t *attributes, pid_t group);
int posix_spawnattr_getschedpolicy(const posix_spawnattr_t *attributes, int *policy);
int posix_spawnattr_setschedpolicy(posix_spawnattr_t *attributes, int policy);
int posix_spawnattr_getschedparam(const posix_spawnattr_t *attributes, struct sched_param *parameter);
int posix_spawnattr_setschedparam(posix_spawnattr_t *attributes, const struct sched_param *parameter);
int posix_spawn_file_actions_init(posix_spawn_file_actions_t *actions);
int posix_spawn_file_actions_destroy(posix_spawn_file_actions_t *actions);
int posix_spawn_file_actions_addopen(posix_spawn_file_actions_t *actions,
                                     int fd, const char *path, int flags, mode_t mode);
int posix_spawn_file_actions_addclose(posix_spawn_file_actions_t *actions, int fd);
int posix_spawn_file_actions_adddup2(posix_spawn_file_actions_t *actions,
                                     int fd, int new_fd);
#endif
