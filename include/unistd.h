#ifndef _UNISTD_H
#define _UNISTD_H 1
#include <rcc/features.h>
#include <rcc/_types.h>
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
#define F_OK 0
#define X_OK 1
#define W_OK 2
#define R_OK 4
#define POSIX_FADV_NORMAL 0
#define POSIX_FADV_RANDOM 1
#define POSIX_FADV_SEQUENTIAL 2
#define POSIX_FADV_WILLNEED 3
#define POSIX_FADV_DONTNEED 4
#define POSIX_FADV_NOREUSE 5
ssize_t read(int fd, void *buffer, size_t count);
ssize_t write(int fd, const void *buffer, size_t count);
int close(int fd);
void _exit(int status);
#ifdef __RCC_USE_POSIX
int access(const char *path, int mode);
int fsync(int fd);
int fdatasync(int fd);
int unlink(const char *path);
int rmdir(const char *path);
int chdir(const char *path);
char *getcwd(char *buffer, size_t size);
off_t lseek(int fd, off_t offset, int whence);
pid_t getpid(void);
pid_t fork(void);
uid_t getuid(void);
uid_t geteuid(void);
gid_t getgid(void);
gid_t getegid(void);
int pipe(int descriptors[2]);
int dup(int descriptor);
int dup2(int old_descriptor, int new_descriptor);
int execv(const char *path, char *const arguments[]);
int execve(const char *path, char *const arguments[], char *const environment[]);
int execvp(const char *file, char *const arguments[]);
int execl(const char *path, const char *argument, ...);
int execlp(const char *file, const char *argument, ...);
int execle(const char *path, const char *argument, ...);
ssize_t pread(int fd, void *buffer, size_t count, off_t offset);
ssize_t pwrite(int fd, const void *buffer, size_t count, off_t offset);
int truncate(const char *path, off_t length);
int ftruncate(int fd, off_t length);
int link(const char *old_path, const char *new_path);
int symlink(const char *target, const char *link_path);
ssize_t readlink(const char *path, char *buffer, size_t size);
int isatty(int descriptor);
char *ttyname(int descriptor);
int gethostname(char *name, size_t size);
unsigned int sleep(unsigned int seconds);
int usleep(unsigned int microseconds);
void sync(void);
#ifdef __RCC_USE_GNU
int syncfs(int descriptor);
#endif
int posix_fadvise(int fd, off_t offset, off_t length, int advice);
int setpgid(pid_t process, pid_t process_group);
extern char *optarg;
extern int optind;
extern int opterr;
extern int optopt;
int getopt(int argc, char *const argv[], const char *short_options);
#endif
#ifdef __RCC_USE_GNU
int getpagesize(void);
long syscall(long number, ...);
#endif
#endif
