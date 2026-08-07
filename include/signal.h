#ifndef _SIGNAL_H
#define _SIGNAL_H 1
#include <rcc/_types.h>

#define SIG_DFL ((sighandler_t)0)
#define SIG_IGN ((sighandler_t)1)
#define SIG_ERR ((sighandler_t)-1)
#define SIGHUP 1
#define SIGINT 2
#define SIGQUIT 3
#define SIGILL 4
#define SIGTRAP 5
#define SIGABRT 6
#define SIGBUS 7
#define SIGFPE 8
#define SIGKILL 9
#define SIGUSR1 10
#define SIGSEGV 11
#define SIGUSR2 12
#define SIGPIPE 13
#define SIGALRM 14
#define SIGTERM 15
#define SIGCHLD 17
#define SIGCONT 18
#define SIGSTOP 19
#define SIGTSTP 20
#define SIGTTIN 21
#define SIGTTOU 22

#define SIG_BLOCK 0
#define SIG_UNBLOCK 1
#define SIG_SETMASK 2

#define SA_NOCLDSTOP 0x00000001
#define SA_NOCLDWAIT 0x00000002
#define SA_SIGINFO 0x00000004
#define SA_ONSTACK 0x08000000
#define SA_RESTART 0x10000000
#define SA_NODEFER 0x40000000
#define SA_RESETHAND 0x80000000

typedef int sig_atomic_t;
typedef void (*sighandler_t)(int);
typedef struct {
    unsigned long __val[16];
} sigset_t;

struct sigaction {
    sighandler_t sa_handler;
    sigset_t sa_mask;
    int sa_flags;
    void (*sa_restorer)(void);
};

sighandler_t signal(int signal_number, sighandler_t handler);
int raise(int signal_number);
int kill(pid_t process, int signal_number);
int sigemptyset(sigset_t *set);
int sigfillset(sigset_t *set);
int sigaddset(sigset_t *set, int signal_number);
int sigdelset(sigset_t *set, int signal_number);
int sigismember(const sigset_t *set, int signal_number);
int sigaction(int signal_number, const struct sigaction *action,
              struct sigaction *old_action);
int sigprocmask(int how, const sigset_t *set, sigset_t *old_set);
int pthread_sigmask(int how, const sigset_t *set, sigset_t *old_set);
int sigpending(sigset_t *set);
int sigsuspend(const sigset_t *mask);

#endif
