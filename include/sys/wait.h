#ifndef _SYS_WAIT_H
#define _SYS_WAIT_H 1
#include <rcc/features.h>
#include <rcc/_types.h>

#define WNOHANG 1
#define WUNTRACED 2
#define WCONTINUED 8
#define WEXITSTATUS(status) (((status) >> 8) & 0xff)
#define WTERMSIG(status) ((status) & 0x7f)
#define WIFEXITED(status) (WTERMSIG(status) == 0)
#define WIFSIGNALED(status) (((signed char)(((status) & 0x7f) + 1) >> 1) > 0)

pid_t wait(int *status);
pid_t waitpid(pid_t process, int *status, int options);

#ifdef __RCC_USE_GNU
struct rusage;
pid_t wait4(pid_t process, int *status, int options,
            struct rusage *resource_usage);
#endif

#endif
