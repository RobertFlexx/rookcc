#ifndef _SIGNAL_H
#define _SIGNAL_H 1
#define SIG_DFL 0
#define SIG_IGN 1
#define SIGINT 2
#define SIGILL 4
#define SIGABRT 6
#define SIGFPE 8
#define SIGKILL 9
#define SIGSEGV 11
#define SIGPIPE 13
#define SIGTERM 15
typedef int sig_atomic_t;
typedef void (*sighandler_t)(int);
sighandler_t signal(int signal_number, sighandler_t handler);
#endif
