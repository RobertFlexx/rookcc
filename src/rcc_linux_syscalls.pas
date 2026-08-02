unit rcc_linux_syscalls;

{$mode objfpc}{$H+}

interface

uses SysUtils, rcc_types;

type
  TLinuxSyscallDescriptor = record
    Architecture: string;
    Name: string;
    Number: LongInt;
    Category: string;
  end;
  TLinuxSyscallDescriptorArray = array of TLinuxSyscallDescriptor;

function BuildLinuxSyscallCatalog: TLinuxSyscallDescriptorArray;
function FindLinuxSyscall(const ACatalog: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string;
  out ADescriptor: TLinuxSyscallDescriptor): Boolean;
function LinuxSyscallCatalogSummary(
  const ACatalog: TLinuxSyscallDescriptorArray): string;

implementation

procedure AddSyscall(var AValues: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string; ANumber: LongInt;
  const ACategory: string);
var N: LongInt;
begin
  N := Length(AValues); SetLength(AValues, N + 1);
  AValues[N].Architecture := AArchitecture;
  AValues[N].Name := AName;
  AValues[N].Number := ANumber;
  AValues[N].Category := ACategory;
end;

function BuildLinuxSyscallCatalog: TLinuxSyscallDescriptorArray;
begin
  Result := nil;
  AddSyscall(Result,
    'x86_64', 'read',
    0, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'write',
    1, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'open',
    2, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'close',
    3, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'stat',
    4, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fstat',
    5, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'lstat',
    6, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'poll',
    7, 'ipc');
  AddSyscall(Result,
    'x86_64', 'lseek',
    8, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mmap',
    9, 'memory');
  AddSyscall(Result,
    'x86_64', 'mprotect',
    10, 'memory');
  AddSyscall(Result,
    'x86_64', 'munmap',
    11, 'memory');
  AddSyscall(Result,
    'x86_64', 'brk',
    12, 'memory');
  AddSyscall(Result,
    'x86_64', 'rt_sigaction',
    13, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'rt_sigprocmask',
    14, 'process');
  AddSyscall(Result,
    'x86_64', 'rt_sigreturn',
    15, 'process');
  AddSyscall(Result,
    'x86_64', 'ioctl',
    16, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pread64',
    17, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pwrite64',
    18, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'readv',
    19, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'writev',
    20, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'access',
    21, 'process');
  AddSyscall(Result,
    'x86_64', 'pipe',
    22, 'process');
  AddSyscall(Result,
    'x86_64', 'select',
    23, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_yield',
    24, 'process');
  AddSyscall(Result,
    'x86_64', 'mremap',
    25, 'process');
  AddSyscall(Result,
    'x86_64', 'msync',
    26, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mincore',
    27, 'process');
  AddSyscall(Result,
    'x86_64', 'madvise',
    28, 'memory');
  AddSyscall(Result,
    'x86_64', 'shmget',
    29, 'ipc');
  AddSyscall(Result,
    'x86_64', 'shmat',
    30, 'ipc');
  AddSyscall(Result,
    'x86_64', 'shmctl',
    31, 'ipc');
  AddSyscall(Result,
    'x86_64', 'dup',
    32, 'process');
  AddSyscall(Result,
    'x86_64', 'dup2',
    33, 'process');
  AddSyscall(Result,
    'x86_64', 'pause',
    34, 'process');
  AddSyscall(Result,
    'x86_64', 'nanosleep',
    35, 'time');
  AddSyscall(Result,
    'x86_64', 'getitimer',
    36, 'time');
  AddSyscall(Result,
    'x86_64', 'alarm',
    37, 'process');
  AddSyscall(Result,
    'x86_64', 'setitimer',
    38, 'time');
  AddSyscall(Result,
    'x86_64', 'getpid',
    39, 'process');
  AddSyscall(Result,
    'x86_64', 'sendfile',
    40, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'socket',
    41, 'network');
  AddSyscall(Result,
    'x86_64', 'connect',
    42, 'network');
  AddSyscall(Result,
    'x86_64', 'accept',
    43, 'network');
  AddSyscall(Result,
    'x86_64', 'sendto',
    44, 'network');
  AddSyscall(Result,
    'x86_64', 'recvfrom',
    45, 'network');
  AddSyscall(Result,
    'x86_64', 'sendmsg',
    46, 'network');
  AddSyscall(Result,
    'x86_64', 'recvmsg',
    47, 'network');
  AddSyscall(Result,
    'x86_64', 'shutdown',
    48, 'process');
  AddSyscall(Result,
    'x86_64', 'bind',
    49, 'network');
  AddSyscall(Result,
    'x86_64', 'listen',
    50, 'network');
  AddSyscall(Result,
    'x86_64', 'getsockname',
    51, 'process');
  AddSyscall(Result,
    'x86_64', 'getpeername',
    52, 'process');
  AddSyscall(Result,
    'x86_64', 'socketpair',
    53, 'network');
  AddSyscall(Result,
    'x86_64', 'setsockopt',
    54, 'process');
  AddSyscall(Result,
    'x86_64', 'getsockopt',
    55, 'process');
  AddSyscall(Result,
    'x86_64', 'clone',
    56, 'process');
  AddSyscall(Result,
    'x86_64', 'fork',
    57, 'process');
  AddSyscall(Result,
    'x86_64', 'vfork',
    58, 'process');
  AddSyscall(Result,
    'x86_64', 'execve',
    59, 'process');
  AddSyscall(Result,
    'x86_64', 'exit',
    60, 'process');
  AddSyscall(Result,
    'x86_64', 'wait4',
    61, 'process');
  AddSyscall(Result,
    'x86_64', 'kill',
    62, 'process');
  AddSyscall(Result,
    'x86_64', 'uname',
    63, 'process');
  AddSyscall(Result,
    'x86_64', 'semget',
    64, 'ipc');
  AddSyscall(Result,
    'x86_64', 'semop',
    65, 'ipc');
  AddSyscall(Result,
    'x86_64', 'semctl',
    66, 'ipc');
  AddSyscall(Result,
    'x86_64', 'shmdt',
    67, 'ipc');
  AddSyscall(Result,
    'x86_64', 'msgget',
    68, 'ipc');
  AddSyscall(Result,
    'x86_64', 'msgsnd',
    69, 'ipc');
  AddSyscall(Result,
    'x86_64', 'msgrcv',
    70, 'ipc');
  AddSyscall(Result,
    'x86_64', 'msgctl',
    71, 'ipc');
  AddSyscall(Result,
    'x86_64', 'fcntl',
    72, 'process');
  AddSyscall(Result,
    'x86_64', 'flock',
    73, 'process');
  AddSyscall(Result,
    'x86_64', 'fsync',
    74, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fdatasync',
    75, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'truncate',
    76, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'ftruncate',
    77, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'getdents',
    78, 'process');
  AddSyscall(Result,
    'x86_64', 'getcwd',
    79, 'process');
  AddSyscall(Result,
    'x86_64', 'chdir',
    80, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fchdir',
    81, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'rename',
    82, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mkdir',
    83, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'rmdir',
    84, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'creat',
    85, 'process');
  AddSyscall(Result,
    'x86_64', 'link',
    86, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'unlink',
    87, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'symlink',
    88, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'readlink',
    89, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'chmod',
    90, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fchmod',
    91, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'chown',
    92, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fchown',
    93, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'lchown',
    94, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'umask',
    95, 'process');
  AddSyscall(Result,
    'x86_64', 'gettimeofday',
    96, 'time');
  AddSyscall(Result,
    'x86_64', 'getrlimit',
    97, 'process');
  AddSyscall(Result,
    'x86_64', 'getrusage',
    98, 'process');
  AddSyscall(Result,
    'x86_64', 'sysinfo',
    99, 'process');
  AddSyscall(Result,
    'x86_64', 'times',
    100, 'time');
  AddSyscall(Result,
    'x86_64', 'ptrace',
    101, 'process');
  AddSyscall(Result,
    'x86_64', 'getuid',
    102, 'process');
  AddSyscall(Result,
    'x86_64', 'syslog',
    103, 'process');
  AddSyscall(Result,
    'x86_64', 'getgid',
    104, 'process');
  AddSyscall(Result,
    'x86_64', 'setuid',
    105, 'process');
  AddSyscall(Result,
    'x86_64', 'setgid',
    106, 'process');
  AddSyscall(Result,
    'x86_64', 'geteuid',
    107, 'process');
  AddSyscall(Result,
    'x86_64', 'getegid',
    108, 'process');
  AddSyscall(Result,
    'x86_64', 'setpgid',
    109, 'process');
  AddSyscall(Result,
    'x86_64', 'getppid',
    110, 'process');
  AddSyscall(Result,
    'x86_64', 'getpgrp',
    111, 'process');
  AddSyscall(Result,
    'x86_64', 'setsid',
    112, 'process');
  AddSyscall(Result,
    'x86_64', 'setreuid',
    113, 'process');
  AddSyscall(Result,
    'x86_64', 'setregid',
    114, 'process');
  AddSyscall(Result,
    'x86_64', 'getgroups',
    115, 'process');
  AddSyscall(Result,
    'x86_64', 'setgroups',
    116, 'process');
  AddSyscall(Result,
    'x86_64', 'setresuid',
    117, 'process');
  AddSyscall(Result,
    'x86_64', 'getresuid',
    118, 'process');
  AddSyscall(Result,
    'x86_64', 'setresgid',
    119, 'process');
  AddSyscall(Result,
    'x86_64', 'getresgid',
    120, 'process');
  AddSyscall(Result,
    'x86_64', 'getpgid',
    121, 'process');
  AddSyscall(Result,
    'x86_64', 'setfsuid',
    122, 'process');
  AddSyscall(Result,
    'x86_64', 'setfsgid',
    123, 'process');
  AddSyscall(Result,
    'x86_64', 'getsid',
    124, 'process');
  AddSyscall(Result,
    'x86_64', 'capget',
    125, 'process');
  AddSyscall(Result,
    'x86_64', 'capset',
    126, 'process');
  AddSyscall(Result,
    'x86_64', 'rt_sigpending',
    127, 'process');
  AddSyscall(Result,
    'x86_64', 'rt_sigtimedwait',
    128, 'time');
  AddSyscall(Result,
    'x86_64', 'rt_sigqueueinfo',
    129, 'process');
  AddSyscall(Result,
    'x86_64', 'rt_sigsuspend',
    130, 'process');
  AddSyscall(Result,
    'x86_64', 'sigaltstack',
    131, 'process');
  AddSyscall(Result,
    'x86_64', 'utime',
    132, 'time');
  AddSyscall(Result,
    'x86_64', 'mknod',
    133, 'process');
  AddSyscall(Result,
    'x86_64', 'uselib',
    134, 'process');
  AddSyscall(Result,
    'x86_64', 'personality',
    135, 'process');
  AddSyscall(Result,
    'x86_64', 'ustat',
    136, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'statfs',
    137, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fstatfs',
    138, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'sysfs',
    139, 'process');
  AddSyscall(Result,
    'x86_64', 'getpriority',
    140, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'setpriority',
    141, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'sched_setparam',
    142, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_getparam',
    143, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_setscheduler',
    144, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_getscheduler',
    145, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_get_priority_max',
    146, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'sched_get_priority_min',
    147, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'sched_rr_get_interval',
    148, 'process');
  AddSyscall(Result,
    'x86_64', 'mlock',
    149, 'process');
  AddSyscall(Result,
    'x86_64', 'munlock',
    150, 'process');
  AddSyscall(Result,
    'x86_64', 'mlockall',
    151, 'process');
  AddSyscall(Result,
    'x86_64', 'munlockall',
    152, 'process');
  AddSyscall(Result,
    'x86_64', 'vhangup',
    153, 'process');
  AddSyscall(Result,
    'x86_64', 'modify_ldt',
    154, 'process');
  AddSyscall(Result,
    'x86_64', 'pivot_root',
    155, 'process');
  AddSyscall(Result,
    'x86_64', '_sysctl',
    156, 'process');
  AddSyscall(Result,
    'x86_64', 'prctl',
    157, 'process');
  AddSyscall(Result,
    'x86_64', 'arch_prctl',
    158, 'process');
  AddSyscall(Result,
    'x86_64', 'adjtimex',
    159, 'time');
  AddSyscall(Result,
    'x86_64', 'setrlimit',
    160, 'process');
  AddSyscall(Result,
    'x86_64', 'chroot',
    161, 'process');
  AddSyscall(Result,
    'x86_64', 'sync',
    162, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'acct',
    163, 'process');
  AddSyscall(Result,
    'x86_64', 'settimeofday',
    164, 'time');
  AddSyscall(Result,
    'x86_64', 'mount',
    165, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'umount2',
    166, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'swapon',
    167, 'process');
  AddSyscall(Result,
    'x86_64', 'swapoff',
    168, 'process');
  AddSyscall(Result,
    'x86_64', 'reboot',
    169, 'process');
  AddSyscall(Result,
    'x86_64', 'sethostname',
    170, 'process');
  AddSyscall(Result,
    'x86_64', 'setdomainname',
    171, 'process');
  AddSyscall(Result,
    'x86_64', 'iopl',
    172, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'ioperm',
    173, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'create_module',
    174, 'process');
  AddSyscall(Result,
    'x86_64', 'init_module',
    175, 'process');
  AddSyscall(Result,
    'x86_64', 'delete_module',
    176, 'process');
  AddSyscall(Result,
    'x86_64', 'get_kernel_syms',
    177, 'process');
  AddSyscall(Result,
    'x86_64', 'query_module',
    178, 'process');
  AddSyscall(Result,
    'x86_64', 'quotactl',
    179, 'process');
  AddSyscall(Result,
    'x86_64', 'nfsservctl',
    180, 'process');
  AddSyscall(Result,
    'x86_64', 'getpmsg',
    181, 'ipc');
  AddSyscall(Result,
    'x86_64', 'putpmsg',
    182, 'ipc');
  AddSyscall(Result,
    'x86_64', 'afs_syscall',
    183, 'process');
  AddSyscall(Result,
    'x86_64', 'tuxcall',
    184, 'process');
  AddSyscall(Result,
    'x86_64', 'security',
    185, 'process');
  AddSyscall(Result,
    'x86_64', 'gettid',
    186, 'process');
  AddSyscall(Result,
    'x86_64', 'readahead',
    187, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'setxattr',
    188, 'process');
  AddSyscall(Result,
    'x86_64', 'lsetxattr',
    189, 'process');
  AddSyscall(Result,
    'x86_64', 'fsetxattr',
    190, 'process');
  AddSyscall(Result,
    'x86_64', 'getxattr',
    191, 'process');
  AddSyscall(Result,
    'x86_64', 'lgetxattr',
    192, 'process');
  AddSyscall(Result,
    'x86_64', 'fgetxattr',
    193, 'process');
  AddSyscall(Result,
    'x86_64', 'listxattr',
    194, 'process');
  AddSyscall(Result,
    'x86_64', 'llistxattr',
    195, 'process');
  AddSyscall(Result,
    'x86_64', 'flistxattr',
    196, 'process');
  AddSyscall(Result,
    'x86_64', 'removexattr',
    197, 'process');
  AddSyscall(Result,
    'x86_64', 'lremovexattr',
    198, 'process');
  AddSyscall(Result,
    'x86_64', 'fremovexattr',
    199, 'process');
  AddSyscall(Result,
    'x86_64', 'tkill',
    200, 'process');
  AddSyscall(Result,
    'x86_64', 'time',
    201, 'time');
  AddSyscall(Result,
    'x86_64', 'futex',
    202, 'ipc');
  AddSyscall(Result,
    'x86_64', 'sched_setaffinity',
    203, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_getaffinity',
    204, 'process');
  AddSyscall(Result,
    'x86_64', 'set_thread_area',
    205, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_setup',
    206, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_destroy',
    207, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_getevents',
    208, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_submit',
    209, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_cancel',
    210, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'get_thread_area',
    211, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'lookup_dcookie',
    212, 'process');
  AddSyscall(Result,
    'x86_64', 'epoll_create',
    213, 'ipc');
  AddSyscall(Result,
    'x86_64', 'epoll_ctl_old',
    214, 'ipc');
  AddSyscall(Result,
    'x86_64', 'epoll_wait_old',
    215, 'ipc');
  AddSyscall(Result,
    'x86_64', 'remap_file_pages',
    216, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'getdents64',
    217, 'process');
  AddSyscall(Result,
    'x86_64', 'set_tid_address',
    218, 'process');
  AddSyscall(Result,
    'x86_64', 'restart_syscall',
    219, 'process');
  AddSyscall(Result,
    'x86_64', 'semtimedop',
    220, 'time');
  AddSyscall(Result,
    'x86_64', 'fadvise64',
    221, 'process');
  AddSyscall(Result,
    'x86_64', 'timer_create',
    222, 'time');
  AddSyscall(Result,
    'x86_64', 'timer_settime',
    223, 'time');
  AddSyscall(Result,
    'x86_64', 'timer_gettime',
    224, 'time');
  AddSyscall(Result,
    'x86_64', 'timer_getoverrun',
    225, 'time');
  AddSyscall(Result,
    'x86_64', 'timer_delete',
    226, 'time');
  AddSyscall(Result,
    'x86_64', 'clock_settime',
    227, 'time');
  AddSyscall(Result,
    'x86_64', 'clock_gettime',
    228, 'time');
  AddSyscall(Result,
    'x86_64', 'clock_getres',
    229, 'time');
  AddSyscall(Result,
    'x86_64', 'clock_nanosleep',
    230, 'time');
  AddSyscall(Result,
    'x86_64', 'exit_group',
    231, 'process');
  AddSyscall(Result,
    'x86_64', 'epoll_wait',
    232, 'ipc');
  AddSyscall(Result,
    'x86_64', 'epoll_ctl',
    233, 'ipc');
  AddSyscall(Result,
    'x86_64', 'tgkill',
    234, 'process');
  AddSyscall(Result,
    'x86_64', 'utimes',
    235, 'time');
  AddSyscall(Result,
    'x86_64', 'vserver',
    236, 'process');
  AddSyscall(Result,
    'x86_64', 'mbind',
    237, 'network');
  AddSyscall(Result,
    'x86_64', 'set_mempolicy',
    238, 'process');
  AddSyscall(Result,
    'x86_64', 'get_mempolicy',
    239, 'process');
  AddSyscall(Result,
    'x86_64', 'mq_open',
    240, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mq_unlink',
    241, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mq_timedsend',
    242, 'network');
  AddSyscall(Result,
    'x86_64', 'mq_timedreceive',
    243, 'time');
  AddSyscall(Result,
    'x86_64', 'mq_notify',
    244, 'process');
  AddSyscall(Result,
    'x86_64', 'mq_getsetattr',
    245, 'process');
  AddSyscall(Result,
    'x86_64', 'kexec_load',
    246, 'process');
  AddSyscall(Result,
    'x86_64', 'waitid',
    247, 'process');
  AddSyscall(Result,
    'x86_64', 'add_key',
    248, 'process');
  AddSyscall(Result,
    'x86_64', 'request_key',
    249, 'process');
  AddSyscall(Result,
    'x86_64', 'keyctl',
    250, 'process');
  AddSyscall(Result,
    'x86_64', 'ioprio_set',
    251, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'ioprio_get',
    252, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'inotify_init',
    253, 'process');
  AddSyscall(Result,
    'x86_64', 'inotify_add_watch',
    254, 'process');
  AddSyscall(Result,
    'x86_64', 'inotify_rm_watch',
    255, 'process');
  AddSyscall(Result,
    'x86_64', 'migrate_pages',
    256, 'process');
  AddSyscall(Result,
    'x86_64', 'openat',
    257, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mkdirat',
    258, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'mknodat',
    259, 'process');
  AddSyscall(Result,
    'x86_64', 'fchownat',
    260, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'futimesat',
    261, 'time');
  AddSyscall(Result,
    'x86_64', 'newfstatat',
    262, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'unlinkat',
    263, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'renameat',
    264, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'linkat',
    265, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'symlinkat',
    266, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'readlinkat',
    267, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fchmodat',
    268, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'faccessat',
    269, 'process');
  AddSyscall(Result,
    'x86_64', 'pselect6',
    270, 'process');
  AddSyscall(Result,
    'x86_64', 'ppoll',
    271, 'ipc');
  AddSyscall(Result,
    'x86_64', 'unshare',
    272, 'process');
  AddSyscall(Result,
    'x86_64', 'set_robust_list',
    273, 'process');
  AddSyscall(Result,
    'x86_64', 'get_robust_list',
    274, 'process');
  AddSyscall(Result,
    'x86_64', 'splice',
    275, 'process');
  AddSyscall(Result,
    'x86_64', 'tee',
    276, 'process');
  AddSyscall(Result,
    'x86_64', 'sync_file_range',
    277, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'vmsplice',
    278, 'process');
  AddSyscall(Result,
    'x86_64', 'move_pages',
    279, 'process');
  AddSyscall(Result,
    'x86_64', 'utimensat',
    280, 'time');
  AddSyscall(Result,
    'x86_64', 'epoll_pwait',
    281, 'ipc');
  AddSyscall(Result,
    'x86_64', 'signalfd',
    282, 'process');
  AddSyscall(Result,
    'x86_64', 'timerfd_create',
    283, 'time');
  AddSyscall(Result,
    'x86_64', 'eventfd',
    284, 'ipc');
  AddSyscall(Result,
    'x86_64', 'fallocate',
    285, 'process');
  AddSyscall(Result,
    'x86_64', 'timerfd_settime',
    286, 'time');
  AddSyscall(Result,
    'x86_64', 'timerfd_gettime',
    287, 'time');
  AddSyscall(Result,
    'x86_64', 'accept4',
    288, 'network');
  AddSyscall(Result,
    'x86_64', 'signalfd4',
    289, 'process');
  AddSyscall(Result,
    'x86_64', 'eventfd2',
    290, 'ipc');
  AddSyscall(Result,
    'x86_64', 'epoll_create1',
    291, 'ipc');
  AddSyscall(Result,
    'x86_64', 'dup3',
    292, 'process');
  AddSyscall(Result,
    'x86_64', 'pipe2',
    293, 'process');
  AddSyscall(Result,
    'x86_64', 'inotify_init1',
    294, 'process');
  AddSyscall(Result,
    'x86_64', 'preadv',
    295, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pwritev',
    296, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'rt_tgsigqueueinfo',
    297, 'process');
  AddSyscall(Result,
    'x86_64', 'perf_event_open',
    298, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'recvmmsg',
    299, 'network');
  AddSyscall(Result,
    'x86_64', 'fanotify_init',
    300, 'process');
  AddSyscall(Result,
    'x86_64', 'fanotify_mark',
    301, 'process');
  AddSyscall(Result,
    'x86_64', 'prlimit64',
    302, 'process');
  AddSyscall(Result,
    'x86_64', 'name_to_handle_at',
    303, 'process');
  AddSyscall(Result,
    'x86_64', 'open_by_handle_at',
    304, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'clock_adjtime',
    305, 'time');
  AddSyscall(Result,
    'x86_64', 'syncfs',
    306, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'sendmmsg',
    307, 'network');
  AddSyscall(Result,
    'x86_64', 'setns',
    308, 'process');
  AddSyscall(Result,
    'x86_64', 'getcpu',
    309, 'process');
  AddSyscall(Result,
    'x86_64', 'process_vm_readv',
    310, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'process_vm_writev',
    311, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'kcmp',
    312, 'process');
  AddSyscall(Result,
    'x86_64', 'finit_module',
    313, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_setattr',
    314, 'process');
  AddSyscall(Result,
    'x86_64', 'sched_getattr',
    315, 'process');
  AddSyscall(Result,
    'x86_64', 'renameat2',
    316, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'seccomp',
    317, 'process');
  AddSyscall(Result,
    'x86_64', 'getrandom',
    318, 'process');
  AddSyscall(Result,
    'x86_64', 'memfd_create',
    319, 'memory');
  AddSyscall(Result,
    'x86_64', 'kexec_file_load',
    320, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'bpf',
    321, 'process');
  AddSyscall(Result,
    'x86_64', 'execveat',
    322, 'process');
  AddSyscall(Result,
    'x86_64', 'userfaultfd',
    323, 'process');
  AddSyscall(Result,
    'x86_64', 'membarrier',
    324, 'process');
  AddSyscall(Result,
    'x86_64', 'mlock2',
    325, 'process');
  AddSyscall(Result,
    'x86_64', 'copy_file_range',
    326, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'preadv2',
    327, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pwritev2',
    328, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pkey_mprotect',
    329, 'memory');
  AddSyscall(Result,
    'x86_64', 'pkey_alloc',
    330, 'process');
  AddSyscall(Result,
    'x86_64', 'pkey_free',
    331, 'process');
  AddSyscall(Result,
    'x86_64', 'statx',
    332, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_pgetevents',
    333, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'rseq',
    334, 'process');
  AddSyscall(Result,
    'x86_64', 'uretprobe',
    335, 'process');
  AddSyscall(Result,
    'x86_64', 'pidfd_send_signal',
    424, 'network');
  AddSyscall(Result,
    'x86_64', 'io_uring_setup',
    425, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_uring_enter',
    426, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'io_uring_register',
    427, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'open_tree',
    428, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'move_mount',
    429, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fsopen',
    430, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fsconfig',
    431, 'process');
  AddSyscall(Result,
    'x86_64', 'fsmount',
    432, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fspick',
    433, 'process');
  AddSyscall(Result,
    'x86_64', 'pidfd_open',
    434, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'clone3',
    435, 'process');
  AddSyscall(Result,
    'x86_64', 'close_range',
    436, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'openat2',
    437, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'pidfd_getfd',
    438, 'process');
  AddSyscall(Result,
    'x86_64', 'faccessat2',
    439, 'process');
  AddSyscall(Result,
    'x86_64', 'process_madvise',
    440, 'memory');
  AddSyscall(Result,
    'x86_64', 'epoll_pwait2',
    441, 'ipc');
  AddSyscall(Result,
    'x86_64', 'mount_setattr',
    442, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'quotactl_fd',
    443, 'process');
  AddSyscall(Result,
    'x86_64', 'landlock_create_ruleset',
    444, 'process');
  AddSyscall(Result,
    'x86_64', 'landlock_add_rule',
    445, 'process');
  AddSyscall(Result,
    'x86_64', 'landlock_restrict_self',
    446, 'process');
  AddSyscall(Result,
    'x86_64', 'memfd_secret',
    447, 'memory');
  AddSyscall(Result,
    'x86_64', 'process_mrelease',
    448, 'process');
  AddSyscall(Result,
    'x86_64', 'futex_waitv',
    449, 'ipc');
  AddSyscall(Result,
    'x86_64', 'set_mempolicy_home_node',
    450, 'process');
  AddSyscall(Result,
    'x86_64', 'cachestat',
    451, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'fchmodat2',
    452, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'map_shadow_stack',
    453, 'process');
  AddSyscall(Result,
    'x86_64', 'futex_wake',
    454, 'ipc');
  AddSyscall(Result,
    'x86_64', 'futex_wait',
    455, 'ipc');
  AddSyscall(Result,
    'x86_64', 'futex_requeue',
    456, 'ipc');
  AddSyscall(Result,
    'x86_64', 'statmount',
    457, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'listmount',
    458, 'filesystem');
  AddSyscall(Result,
    'x86_64', 'lsm_get_self_attr',
    459, 'process');
  AddSyscall(Result,
    'x86_64', 'lsm_set_self_attr',
    460, 'process');
  AddSyscall(Result,
    'x86_64', 'lsm_list_modules',
    461, 'process');
  AddSyscall(Result,
    'x86_64', 'mseal',
    462, 'process');
  AddSyscall(Result,
    'aarch64', 'io_setup',
    0, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_destroy',
    1, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_submit',
    2, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_cancel',
    3, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_getevents',
    4, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'setxattr',
    5, 'process');
  AddSyscall(Result,
    'aarch64', 'lsetxattr',
    6, 'process');
  AddSyscall(Result,
    'aarch64', 'fsetxattr',
    7, 'process');
  AddSyscall(Result,
    'aarch64', 'getxattr',
    8, 'process');
  AddSyscall(Result,
    'aarch64', 'lgetxattr',
    9, 'process');
  AddSyscall(Result,
    'aarch64', 'fgetxattr',
    10, 'process');
  AddSyscall(Result,
    'aarch64', 'listxattr',
    11, 'process');
  AddSyscall(Result,
    'aarch64', 'llistxattr',
    12, 'process');
  AddSyscall(Result,
    'aarch64', 'flistxattr',
    13, 'process');
  AddSyscall(Result,
    'aarch64', 'removexattr',
    14, 'process');
  AddSyscall(Result,
    'aarch64', 'lremovexattr',
    15, 'process');
  AddSyscall(Result,
    'aarch64', 'fremovexattr',
    16, 'process');
  AddSyscall(Result,
    'aarch64', 'getcwd',
    17, 'process');
  AddSyscall(Result,
    'aarch64', 'lookup_dcookie',
    18, 'process');
  AddSyscall(Result,
    'aarch64', 'eventfd2',
    19, 'ipc');
  AddSyscall(Result,
    'aarch64', 'epoll_create1',
    20, 'ipc');
  AddSyscall(Result,
    'aarch64', 'epoll_ctl',
    21, 'ipc');
  AddSyscall(Result,
    'aarch64', 'epoll_pwait',
    22, 'ipc');
  AddSyscall(Result,
    'aarch64', 'dup',
    23, 'process');
  AddSyscall(Result,
    'aarch64', 'dup3',
    24, 'process');
  AddSyscall(Result,
    'aarch64', 'inotify_init1',
    26, 'process');
  AddSyscall(Result,
    'aarch64', 'inotify_add_watch',
    27, 'process');
  AddSyscall(Result,
    'aarch64', 'inotify_rm_watch',
    28, 'process');
  AddSyscall(Result,
    'aarch64', 'ioctl',
    29, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'ioprio_set',
    30, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'ioprio_get',
    31, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'flock',
    32, 'process');
  AddSyscall(Result,
    'aarch64', 'mknodat',
    33, 'process');
  AddSyscall(Result,
    'aarch64', 'mkdirat',
    34, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'unlinkat',
    35, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'symlinkat',
    36, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'linkat',
    37, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'renameat',
    38, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'umount2',
    39, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'mount',
    40, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pivot_root',
    41, 'process');
  AddSyscall(Result,
    'aarch64', 'nfsservctl',
    42, 'process');
  AddSyscall(Result,
    'aarch64', 'fallocate',
    47, 'process');
  AddSyscall(Result,
    'aarch64', 'faccessat',
    48, 'process');
  AddSyscall(Result,
    'aarch64', 'chdir',
    49, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fchdir',
    50, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'chroot',
    51, 'process');
  AddSyscall(Result,
    'aarch64', 'fchmod',
    52, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fchmodat',
    53, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fchownat',
    54, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fchown',
    55, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'openat',
    56, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'close',
    57, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'vhangup',
    58, 'process');
  AddSyscall(Result,
    'aarch64', 'pipe2',
    59, 'process');
  AddSyscall(Result,
    'aarch64', 'quotactl',
    60, 'process');
  AddSyscall(Result,
    'aarch64', 'getdents64',
    61, 'process');
  AddSyscall(Result,
    'aarch64', 'read',
    63, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'write',
    64, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'readv',
    65, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'writev',
    66, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pread64',
    67, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pwrite64',
    68, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'preadv',
    69, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pwritev',
    70, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pselect6',
    72, 'process');
  AddSyscall(Result,
    'aarch64', 'ppoll',
    73, 'ipc');
  AddSyscall(Result,
    'aarch64', 'signalfd4',
    74, 'process');
  AddSyscall(Result,
    'aarch64', 'vmsplice',
    75, 'process');
  AddSyscall(Result,
    'aarch64', 'splice',
    76, 'process');
  AddSyscall(Result,
    'aarch64', 'tee',
    77, 'process');
  AddSyscall(Result,
    'aarch64', 'readlinkat',
    78, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'sync',
    81, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fsync',
    82, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fdatasync',
    83, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'sync_file_range2',
    84, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'sync_file_range',
    84, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'timerfd_create',
    85, 'time');
  AddSyscall(Result,
    'aarch64', 'timerfd_settime',
    86, 'time');
  AddSyscall(Result,
    'aarch64', 'timerfd_gettime',
    87, 'time');
  AddSyscall(Result,
    'aarch64', 'utimensat',
    88, 'time');
  AddSyscall(Result,
    'aarch64', 'acct',
    89, 'process');
  AddSyscall(Result,
    'aarch64', 'capget',
    90, 'process');
  AddSyscall(Result,
    'aarch64', 'capset',
    91, 'process');
  AddSyscall(Result,
    'aarch64', 'personality',
    92, 'process');
  AddSyscall(Result,
    'aarch64', 'exit',
    93, 'process');
  AddSyscall(Result,
    'aarch64', 'exit_group',
    94, 'process');
  AddSyscall(Result,
    'aarch64', 'waitid',
    95, 'process');
  AddSyscall(Result,
    'aarch64', 'set_tid_address',
    96, 'process');
  AddSyscall(Result,
    'aarch64', 'unshare',
    97, 'process');
  AddSyscall(Result,
    'aarch64', 'futex',
    98, 'ipc');
  AddSyscall(Result,
    'aarch64', 'set_robust_list',
    99, 'process');
  AddSyscall(Result,
    'aarch64', 'get_robust_list',
    100, 'process');
  AddSyscall(Result,
    'aarch64', 'nanosleep',
    101, 'time');
  AddSyscall(Result,
    'aarch64', 'getitimer',
    102, 'time');
  AddSyscall(Result,
    'aarch64', 'setitimer',
    103, 'time');
  AddSyscall(Result,
    'aarch64', 'kexec_load',
    104, 'process');
  AddSyscall(Result,
    'aarch64', 'init_module',
    105, 'process');
  AddSyscall(Result,
    'aarch64', 'delete_module',
    106, 'process');
  AddSyscall(Result,
    'aarch64', 'timer_create',
    107, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_gettime',
    108, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_getoverrun',
    109, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_settime',
    110, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_delete',
    111, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_settime',
    112, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_gettime',
    113, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_getres',
    114, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_nanosleep',
    115, 'time');
  AddSyscall(Result,
    'aarch64', 'syslog',
    116, 'process');
  AddSyscall(Result,
    'aarch64', 'ptrace',
    117, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_setparam',
    118, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_setscheduler',
    119, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_getscheduler',
    120, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_getparam',
    121, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_setaffinity',
    122, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_getaffinity',
    123, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_yield',
    124, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_get_priority_max',
    125, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'sched_get_priority_min',
    126, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'sched_rr_get_interval',
    127, 'process');
  AddSyscall(Result,
    'aarch64', 'restart_syscall',
    128, 'process');
  AddSyscall(Result,
    'aarch64', 'kill',
    129, 'process');
  AddSyscall(Result,
    'aarch64', 'tkill',
    130, 'process');
  AddSyscall(Result,
    'aarch64', 'tgkill',
    131, 'process');
  AddSyscall(Result,
    'aarch64', 'sigaltstack',
    132, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_sigsuspend',
    133, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_sigaction',
    134, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'rt_sigprocmask',
    135, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_sigpending',
    136, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_sigtimedwait',
    137, 'time');
  AddSyscall(Result,
    'aarch64', 'rt_sigqueueinfo',
    138, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_sigreturn',
    139, 'process');
  AddSyscall(Result,
    'aarch64', 'setpriority',
    140, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'getpriority',
    141, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'reboot',
    142, 'process');
  AddSyscall(Result,
    'aarch64', 'setregid',
    143, 'process');
  AddSyscall(Result,
    'aarch64', 'setgid',
    144, 'process');
  AddSyscall(Result,
    'aarch64', 'setreuid',
    145, 'process');
  AddSyscall(Result,
    'aarch64', 'setuid',
    146, 'process');
  AddSyscall(Result,
    'aarch64', 'setresuid',
    147, 'process');
  AddSyscall(Result,
    'aarch64', 'getresuid',
    148, 'process');
  AddSyscall(Result,
    'aarch64', 'setresgid',
    149, 'process');
  AddSyscall(Result,
    'aarch64', 'getresgid',
    150, 'process');
  AddSyscall(Result,
    'aarch64', 'setfsuid',
    151, 'process');
  AddSyscall(Result,
    'aarch64', 'setfsgid',
    152, 'process');
  AddSyscall(Result,
    'aarch64', 'times',
    153, 'time');
  AddSyscall(Result,
    'aarch64', 'setpgid',
    154, 'process');
  AddSyscall(Result,
    'aarch64', 'getpgid',
    155, 'process');
  AddSyscall(Result,
    'aarch64', 'getsid',
    156, 'process');
  AddSyscall(Result,
    'aarch64', 'setsid',
    157, 'process');
  AddSyscall(Result,
    'aarch64', 'getgroups',
    158, 'process');
  AddSyscall(Result,
    'aarch64', 'setgroups',
    159, 'process');
  AddSyscall(Result,
    'aarch64', 'uname',
    160, 'process');
  AddSyscall(Result,
    'aarch64', 'sethostname',
    161, 'process');
  AddSyscall(Result,
    'aarch64', 'setdomainname',
    162, 'process');
  AddSyscall(Result,
    'aarch64', 'getrlimit',
    163, 'process');
  AddSyscall(Result,
    'aarch64', 'setrlimit',
    164, 'process');
  AddSyscall(Result,
    'aarch64', 'getrusage',
    165, 'process');
  AddSyscall(Result,
    'aarch64', 'umask',
    166, 'process');
  AddSyscall(Result,
    'aarch64', 'prctl',
    167, 'process');
  AddSyscall(Result,
    'aarch64', 'getcpu',
    168, 'process');
  AddSyscall(Result,
    'aarch64', 'gettimeofday',
    169, 'time');
  AddSyscall(Result,
    'aarch64', 'settimeofday',
    170, 'time');
  AddSyscall(Result,
    'aarch64', 'adjtimex',
    171, 'time');
  AddSyscall(Result,
    'aarch64', 'getpid',
    172, 'process');
  AddSyscall(Result,
    'aarch64', 'getppid',
    173, 'process');
  AddSyscall(Result,
    'aarch64', 'getuid',
    174, 'process');
  AddSyscall(Result,
    'aarch64', 'geteuid',
    175, 'process');
  AddSyscall(Result,
    'aarch64', 'getgid',
    176, 'process');
  AddSyscall(Result,
    'aarch64', 'getegid',
    177, 'process');
  AddSyscall(Result,
    'aarch64', 'gettid',
    178, 'process');
  AddSyscall(Result,
    'aarch64', 'sysinfo',
    179, 'process');
  AddSyscall(Result,
    'aarch64', 'mq_open',
    180, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'mq_unlink',
    181, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'mq_timedsend',
    182, 'network');
  AddSyscall(Result,
    'aarch64', 'mq_timedreceive',
    183, 'time');
  AddSyscall(Result,
    'aarch64', 'mq_notify',
    184, 'process');
  AddSyscall(Result,
    'aarch64', 'mq_getsetattr',
    185, 'process');
  AddSyscall(Result,
    'aarch64', 'msgget',
    186, 'ipc');
  AddSyscall(Result,
    'aarch64', 'msgctl',
    187, 'ipc');
  AddSyscall(Result,
    'aarch64', 'msgrcv',
    188, 'ipc');
  AddSyscall(Result,
    'aarch64', 'msgsnd',
    189, 'ipc');
  AddSyscall(Result,
    'aarch64', 'semget',
    190, 'ipc');
  AddSyscall(Result,
    'aarch64', 'semctl',
    191, 'ipc');
  AddSyscall(Result,
    'aarch64', 'semtimedop',
    192, 'time');
  AddSyscall(Result,
    'aarch64', 'semop',
    193, 'ipc');
  AddSyscall(Result,
    'aarch64', 'shmget',
    194, 'ipc');
  AddSyscall(Result,
    'aarch64', 'shmctl',
    195, 'ipc');
  AddSyscall(Result,
    'aarch64', 'shmat',
    196, 'ipc');
  AddSyscall(Result,
    'aarch64', 'shmdt',
    197, 'ipc');
  AddSyscall(Result,
    'aarch64', 'socket',
    198, 'network');
  AddSyscall(Result,
    'aarch64', 'socketpair',
    199, 'network');
  AddSyscall(Result,
    'aarch64', 'bind',
    200, 'network');
  AddSyscall(Result,
    'aarch64', 'listen',
    201, 'network');
  AddSyscall(Result,
    'aarch64', 'accept',
    202, 'network');
  AddSyscall(Result,
    'aarch64', 'connect',
    203, 'network');
  AddSyscall(Result,
    'aarch64', 'getsockname',
    204, 'process');
  AddSyscall(Result,
    'aarch64', 'getpeername',
    205, 'process');
  AddSyscall(Result,
    'aarch64', 'sendto',
    206, 'network');
  AddSyscall(Result,
    'aarch64', 'recvfrom',
    207, 'network');
  AddSyscall(Result,
    'aarch64', 'setsockopt',
    208, 'process');
  AddSyscall(Result,
    'aarch64', 'getsockopt',
    209, 'process');
  AddSyscall(Result,
    'aarch64', 'shutdown',
    210, 'process');
  AddSyscall(Result,
    'aarch64', 'sendmsg',
    211, 'network');
  AddSyscall(Result,
    'aarch64', 'recvmsg',
    212, 'network');
  AddSyscall(Result,
    'aarch64', 'readahead',
    213, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'brk',
    214, 'memory');
  AddSyscall(Result,
    'aarch64', 'munmap',
    215, 'memory');
  AddSyscall(Result,
    'aarch64', 'mremap',
    216, 'process');
  AddSyscall(Result,
    'aarch64', 'add_key',
    217, 'process');
  AddSyscall(Result,
    'aarch64', 'request_key',
    218, 'process');
  AddSyscall(Result,
    'aarch64', 'keyctl',
    219, 'process');
  AddSyscall(Result,
    'aarch64', 'clone',
    220, 'process');
  AddSyscall(Result,
    'aarch64', 'execve',
    221, 'process');
  AddSyscall(Result,
    'aarch64', 'swapon',
    224, 'process');
  AddSyscall(Result,
    'aarch64', 'swapoff',
    225, 'process');
  AddSyscall(Result,
    'aarch64', 'mprotect',
    226, 'memory');
  AddSyscall(Result,
    'aarch64', 'msync',
    227, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'mlock',
    228, 'process');
  AddSyscall(Result,
    'aarch64', 'munlock',
    229, 'process');
  AddSyscall(Result,
    'aarch64', 'mlockall',
    230, 'process');
  AddSyscall(Result,
    'aarch64', 'munlockall',
    231, 'process');
  AddSyscall(Result,
    'aarch64', 'mincore',
    232, 'process');
  AddSyscall(Result,
    'aarch64', 'madvise',
    233, 'memory');
  AddSyscall(Result,
    'aarch64', 'remap_file_pages',
    234, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'mbind',
    235, 'network');
  AddSyscall(Result,
    'aarch64', 'get_mempolicy',
    236, 'process');
  AddSyscall(Result,
    'aarch64', 'set_mempolicy',
    237, 'process');
  AddSyscall(Result,
    'aarch64', 'migrate_pages',
    238, 'process');
  AddSyscall(Result,
    'aarch64', 'move_pages',
    239, 'process');
  AddSyscall(Result,
    'aarch64', 'rt_tgsigqueueinfo',
    240, 'process');
  AddSyscall(Result,
    'aarch64', 'perf_event_open',
    241, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'accept4',
    242, 'network');
  AddSyscall(Result,
    'aarch64', 'recvmmsg',
    243, 'network');
  AddSyscall(Result,
    'aarch64', 'arch_specific_syscall',
    244, 'process');
  AddSyscall(Result,
    'aarch64', 'wait4',
    260, 'process');
  AddSyscall(Result,
    'aarch64', 'prlimit64',
    261, 'process');
  AddSyscall(Result,
    'aarch64', 'fanotify_init',
    262, 'process');
  AddSyscall(Result,
    'aarch64', 'fanotify_mark',
    263, 'process');
  AddSyscall(Result,
    'aarch64', 'name_to_handle_at',
    264, 'process');
  AddSyscall(Result,
    'aarch64', 'open_by_handle_at',
    265, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'clock_adjtime',
    266, 'time');
  AddSyscall(Result,
    'aarch64', 'syncfs',
    267, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'setns',
    268, 'process');
  AddSyscall(Result,
    'aarch64', 'sendmmsg',
    269, 'network');
  AddSyscall(Result,
    'aarch64', 'process_vm_readv',
    270, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'process_vm_writev',
    271, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'kcmp',
    272, 'process');
  AddSyscall(Result,
    'aarch64', 'finit_module',
    273, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_setattr',
    274, 'process');
  AddSyscall(Result,
    'aarch64', 'sched_getattr',
    275, 'process');
  AddSyscall(Result,
    'aarch64', 'renameat2',
    276, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'seccomp',
    277, 'process');
  AddSyscall(Result,
    'aarch64', 'getrandom',
    278, 'process');
  AddSyscall(Result,
    'aarch64', 'memfd_create',
    279, 'memory');
  AddSyscall(Result,
    'aarch64', 'bpf',
    280, 'process');
  AddSyscall(Result,
    'aarch64', 'execveat',
    281, 'process');
  AddSyscall(Result,
    'aarch64', 'userfaultfd',
    282, 'process');
  AddSyscall(Result,
    'aarch64', 'membarrier',
    283, 'process');
  AddSyscall(Result,
    'aarch64', 'mlock2',
    284, 'process');
  AddSyscall(Result,
    'aarch64', 'copy_file_range',
    285, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'preadv2',
    286, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pwritev2',
    287, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pkey_mprotect',
    288, 'memory');
  AddSyscall(Result,
    'aarch64', 'pkey_alloc',
    289, 'process');
  AddSyscall(Result,
    'aarch64', 'pkey_free',
    290, 'process');
  AddSyscall(Result,
    'aarch64', 'statx',
    291, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_pgetevents',
    292, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'rseq',
    293, 'process');
  AddSyscall(Result,
    'aarch64', 'kexec_file_load',
    294, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'clock_gettime64',
    403, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_settime64',
    404, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_adjtime64',
    405, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_getres_time64',
    406, 'time');
  AddSyscall(Result,
    'aarch64', 'clock_nanosleep_time64',
    407, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_gettime64',
    408, 'time');
  AddSyscall(Result,
    'aarch64', 'timer_settime64',
    409, 'time');
  AddSyscall(Result,
    'aarch64', 'timerfd_gettime64',
    410, 'time');
  AddSyscall(Result,
    'aarch64', 'timerfd_settime64',
    411, 'time');
  AddSyscall(Result,
    'aarch64', 'utimensat_time64',
    412, 'time');
  AddSyscall(Result,
    'aarch64', 'pselect6_time64',
    413, 'time');
  AddSyscall(Result,
    'aarch64', 'ppoll_time64',
    414, 'time');
  AddSyscall(Result,
    'aarch64', 'io_pgetevents_time64',
    416, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'recvmmsg_time64',
    417, 'network');
  AddSyscall(Result,
    'aarch64', 'mq_timedsend_time64',
    418, 'network');
  AddSyscall(Result,
    'aarch64', 'mq_timedreceive_time64',
    419, 'time');
  AddSyscall(Result,
    'aarch64', 'semtimedop_time64',
    420, 'time');
  AddSyscall(Result,
    'aarch64', 'rt_sigtimedwait_time64',
    421, 'time');
  AddSyscall(Result,
    'aarch64', 'futex_time64',
    422, 'time');
  AddSyscall(Result,
    'aarch64', 'sched_rr_get_interval_time64',
    423, 'time');
  AddSyscall(Result,
    'aarch64', 'pidfd_send_signal',
    424, 'network');
  AddSyscall(Result,
    'aarch64', 'io_uring_setup',
    425, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_uring_enter',
    426, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'io_uring_register',
    427, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'open_tree',
    428, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'move_mount',
    429, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fsopen',
    430, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fsconfig',
    431, 'process');
  AddSyscall(Result,
    'aarch64', 'fsmount',
    432, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fspick',
    433, 'process');
  AddSyscall(Result,
    'aarch64', 'pidfd_open',
    434, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'clone3',
    435, 'process');
  AddSyscall(Result,
    'aarch64', 'close_range',
    436, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'openat2',
    437, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'pidfd_getfd',
    438, 'process');
  AddSyscall(Result,
    'aarch64', 'faccessat2',
    439, 'process');
  AddSyscall(Result,
    'aarch64', 'process_madvise',
    440, 'memory');
  AddSyscall(Result,
    'aarch64', 'epoll_pwait2',
    441, 'ipc');
  AddSyscall(Result,
    'aarch64', 'mount_setattr',
    442, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'quotactl_fd',
    443, 'process');
  AddSyscall(Result,
    'aarch64', 'landlock_create_ruleset',
    444, 'process');
  AddSyscall(Result,
    'aarch64', 'landlock_add_rule',
    445, 'process');
  AddSyscall(Result,
    'aarch64', 'landlock_restrict_self',
    446, 'process');
  AddSyscall(Result,
    'aarch64', 'memfd_secret',
    447, 'memory');
  AddSyscall(Result,
    'aarch64', 'process_mrelease',
    448, 'process');
  AddSyscall(Result,
    'aarch64', 'futex_waitv',
    449, 'ipc');
  AddSyscall(Result,
    'aarch64', 'set_mempolicy_home_node',
    450, 'process');
  AddSyscall(Result,
    'aarch64', 'cachestat',
    451, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'fchmodat2',
    452, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'map_shadow_stack',
    453, 'process');
  AddSyscall(Result,
    'aarch64', 'futex_wake',
    454, 'ipc');
  AddSyscall(Result,
    'aarch64', 'futex_wait',
    455, 'ipc');
  AddSyscall(Result,
    'aarch64', 'futex_requeue',
    456, 'ipc');
  AddSyscall(Result,
    'aarch64', 'statmount',
    457, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'listmount',
    458, 'filesystem');
  AddSyscall(Result,
    'aarch64', 'lsm_get_self_attr',
    459, 'process');
  AddSyscall(Result,
    'aarch64', 'lsm_set_self_attr',
    460, 'process');
  AddSyscall(Result,
    'aarch64', 'lsm_list_modules',
    461, 'process');
  AddSyscall(Result,
    'aarch64', 'mseal',
    462, 'process');
  AddSyscall(Result,
    'aarch64', 'syscalls',
    463, 'process');
  AddSyscall(Result,
    'riscv64', 'io_setup',
    0, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_destroy',
    1, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_submit',
    2, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_cancel',
    3, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_getevents',
    4, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'setxattr',
    5, 'process');
  AddSyscall(Result,
    'riscv64', 'lsetxattr',
    6, 'process');
  AddSyscall(Result,
    'riscv64', 'fsetxattr',
    7, 'process');
  AddSyscall(Result,
    'riscv64', 'getxattr',
    8, 'process');
  AddSyscall(Result,
    'riscv64', 'lgetxattr',
    9, 'process');
  AddSyscall(Result,
    'riscv64', 'fgetxattr',
    10, 'process');
  AddSyscall(Result,
    'riscv64', 'listxattr',
    11, 'process');
  AddSyscall(Result,
    'riscv64', 'llistxattr',
    12, 'process');
  AddSyscall(Result,
    'riscv64', 'flistxattr',
    13, 'process');
  AddSyscall(Result,
    'riscv64', 'removexattr',
    14, 'process');
  AddSyscall(Result,
    'riscv64', 'lremovexattr',
    15, 'process');
  AddSyscall(Result,
    'riscv64', 'fremovexattr',
    16, 'process');
  AddSyscall(Result,
    'riscv64', 'getcwd',
    17, 'process');
  AddSyscall(Result,
    'riscv64', 'lookup_dcookie',
    18, 'process');
  AddSyscall(Result,
    'riscv64', 'eventfd2',
    19, 'ipc');
  AddSyscall(Result,
    'riscv64', 'epoll_create1',
    20, 'ipc');
  AddSyscall(Result,
    'riscv64', 'epoll_ctl',
    21, 'ipc');
  AddSyscall(Result,
    'riscv64', 'epoll_pwait',
    22, 'ipc');
  AddSyscall(Result,
    'riscv64', 'dup',
    23, 'process');
  AddSyscall(Result,
    'riscv64', 'dup3',
    24, 'process');
  AddSyscall(Result,
    'riscv64', 'inotify_init1',
    26, 'process');
  AddSyscall(Result,
    'riscv64', 'inotify_add_watch',
    27, 'process');
  AddSyscall(Result,
    'riscv64', 'inotify_rm_watch',
    28, 'process');
  AddSyscall(Result,
    'riscv64', 'ioctl',
    29, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'ioprio_set',
    30, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'ioprio_get',
    31, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'flock',
    32, 'process');
  AddSyscall(Result,
    'riscv64', 'mknodat',
    33, 'process');
  AddSyscall(Result,
    'riscv64', 'mkdirat',
    34, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'unlinkat',
    35, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'symlinkat',
    36, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'linkat',
    37, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'renameat',
    38, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'umount2',
    39, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'mount',
    40, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pivot_root',
    41, 'process');
  AddSyscall(Result,
    'riscv64', 'nfsservctl',
    42, 'process');
  AddSyscall(Result,
    'riscv64', 'fallocate',
    47, 'process');
  AddSyscall(Result,
    'riscv64', 'faccessat',
    48, 'process');
  AddSyscall(Result,
    'riscv64', 'chdir',
    49, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fchdir',
    50, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'chroot',
    51, 'process');
  AddSyscall(Result,
    'riscv64', 'fchmod',
    52, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fchmodat',
    53, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fchownat',
    54, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fchown',
    55, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'openat',
    56, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'close',
    57, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'vhangup',
    58, 'process');
  AddSyscall(Result,
    'riscv64', 'pipe2',
    59, 'process');
  AddSyscall(Result,
    'riscv64', 'quotactl',
    60, 'process');
  AddSyscall(Result,
    'riscv64', 'getdents64',
    61, 'process');
  AddSyscall(Result,
    'riscv64', 'read',
    63, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'write',
    64, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'readv',
    65, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'writev',
    66, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pread64',
    67, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pwrite64',
    68, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'preadv',
    69, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pwritev',
    70, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pselect6',
    72, 'process');
  AddSyscall(Result,
    'riscv64', 'ppoll',
    73, 'ipc');
  AddSyscall(Result,
    'riscv64', 'signalfd4',
    74, 'process');
  AddSyscall(Result,
    'riscv64', 'vmsplice',
    75, 'process');
  AddSyscall(Result,
    'riscv64', 'splice',
    76, 'process');
  AddSyscall(Result,
    'riscv64', 'tee',
    77, 'process');
  AddSyscall(Result,
    'riscv64', 'readlinkat',
    78, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'sync',
    81, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fsync',
    82, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fdatasync',
    83, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'sync_file_range2',
    84, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'sync_file_range',
    84, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'timerfd_create',
    85, 'time');
  AddSyscall(Result,
    'riscv64', 'timerfd_settime',
    86, 'time');
  AddSyscall(Result,
    'riscv64', 'timerfd_gettime',
    87, 'time');
  AddSyscall(Result,
    'riscv64', 'utimensat',
    88, 'time');
  AddSyscall(Result,
    'riscv64', 'acct',
    89, 'process');
  AddSyscall(Result,
    'riscv64', 'capget',
    90, 'process');
  AddSyscall(Result,
    'riscv64', 'capset',
    91, 'process');
  AddSyscall(Result,
    'riscv64', 'personality',
    92, 'process');
  AddSyscall(Result,
    'riscv64', 'exit',
    93, 'process');
  AddSyscall(Result,
    'riscv64', 'exit_group',
    94, 'process');
  AddSyscall(Result,
    'riscv64', 'waitid',
    95, 'process');
  AddSyscall(Result,
    'riscv64', 'set_tid_address',
    96, 'process');
  AddSyscall(Result,
    'riscv64', 'unshare',
    97, 'process');
  AddSyscall(Result,
    'riscv64', 'futex',
    98, 'ipc');
  AddSyscall(Result,
    'riscv64', 'set_robust_list',
    99, 'process');
  AddSyscall(Result,
    'riscv64', 'get_robust_list',
    100, 'process');
  AddSyscall(Result,
    'riscv64', 'nanosleep',
    101, 'time');
  AddSyscall(Result,
    'riscv64', 'getitimer',
    102, 'time');
  AddSyscall(Result,
    'riscv64', 'setitimer',
    103, 'time');
  AddSyscall(Result,
    'riscv64', 'kexec_load',
    104, 'process');
  AddSyscall(Result,
    'riscv64', 'init_module',
    105, 'process');
  AddSyscall(Result,
    'riscv64', 'delete_module',
    106, 'process');
  AddSyscall(Result,
    'riscv64', 'timer_create',
    107, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_gettime',
    108, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_getoverrun',
    109, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_settime',
    110, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_delete',
    111, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_settime',
    112, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_gettime',
    113, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_getres',
    114, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_nanosleep',
    115, 'time');
  AddSyscall(Result,
    'riscv64', 'syslog',
    116, 'process');
  AddSyscall(Result,
    'riscv64', 'ptrace',
    117, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_setparam',
    118, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_setscheduler',
    119, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_getscheduler',
    120, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_getparam',
    121, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_setaffinity',
    122, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_getaffinity',
    123, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_yield',
    124, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_get_priority_max',
    125, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'sched_get_priority_min',
    126, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'sched_rr_get_interval',
    127, 'process');
  AddSyscall(Result,
    'riscv64', 'restart_syscall',
    128, 'process');
  AddSyscall(Result,
    'riscv64', 'kill',
    129, 'process');
  AddSyscall(Result,
    'riscv64', 'tkill',
    130, 'process');
  AddSyscall(Result,
    'riscv64', 'tgkill',
    131, 'process');
  AddSyscall(Result,
    'riscv64', 'sigaltstack',
    132, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_sigsuspend',
    133, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_sigaction',
    134, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'rt_sigprocmask',
    135, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_sigpending',
    136, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_sigtimedwait',
    137, 'time');
  AddSyscall(Result,
    'riscv64', 'rt_sigqueueinfo',
    138, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_sigreturn',
    139, 'process');
  AddSyscall(Result,
    'riscv64', 'setpriority',
    140, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'getpriority',
    141, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'reboot',
    142, 'process');
  AddSyscall(Result,
    'riscv64', 'setregid',
    143, 'process');
  AddSyscall(Result,
    'riscv64', 'setgid',
    144, 'process');
  AddSyscall(Result,
    'riscv64', 'setreuid',
    145, 'process');
  AddSyscall(Result,
    'riscv64', 'setuid',
    146, 'process');
  AddSyscall(Result,
    'riscv64', 'setresuid',
    147, 'process');
  AddSyscall(Result,
    'riscv64', 'getresuid',
    148, 'process');
  AddSyscall(Result,
    'riscv64', 'setresgid',
    149, 'process');
  AddSyscall(Result,
    'riscv64', 'getresgid',
    150, 'process');
  AddSyscall(Result,
    'riscv64', 'setfsuid',
    151, 'process');
  AddSyscall(Result,
    'riscv64', 'setfsgid',
    152, 'process');
  AddSyscall(Result,
    'riscv64', 'times',
    153, 'time');
  AddSyscall(Result,
    'riscv64', 'setpgid',
    154, 'process');
  AddSyscall(Result,
    'riscv64', 'getpgid',
    155, 'process');
  AddSyscall(Result,
    'riscv64', 'getsid',
    156, 'process');
  AddSyscall(Result,
    'riscv64', 'setsid',
    157, 'process');
  AddSyscall(Result,
    'riscv64', 'getgroups',
    158, 'process');
  AddSyscall(Result,
    'riscv64', 'setgroups',
    159, 'process');
  AddSyscall(Result,
    'riscv64', 'uname',
    160, 'process');
  AddSyscall(Result,
    'riscv64', 'sethostname',
    161, 'process');
  AddSyscall(Result,
    'riscv64', 'setdomainname',
    162, 'process');
  AddSyscall(Result,
    'riscv64', 'getrlimit',
    163, 'process');
  AddSyscall(Result,
    'riscv64', 'setrlimit',
    164, 'process');
  AddSyscall(Result,
    'riscv64', 'getrusage',
    165, 'process');
  AddSyscall(Result,
    'riscv64', 'umask',
    166, 'process');
  AddSyscall(Result,
    'riscv64', 'prctl',
    167, 'process');
  AddSyscall(Result,
    'riscv64', 'getcpu',
    168, 'process');
  AddSyscall(Result,
    'riscv64', 'gettimeofday',
    169, 'time');
  AddSyscall(Result,
    'riscv64', 'settimeofday',
    170, 'time');
  AddSyscall(Result,
    'riscv64', 'adjtimex',
    171, 'time');
  AddSyscall(Result,
    'riscv64', 'getpid',
    172, 'process');
  AddSyscall(Result,
    'riscv64', 'getppid',
    173, 'process');
  AddSyscall(Result,
    'riscv64', 'getuid',
    174, 'process');
  AddSyscall(Result,
    'riscv64', 'geteuid',
    175, 'process');
  AddSyscall(Result,
    'riscv64', 'getgid',
    176, 'process');
  AddSyscall(Result,
    'riscv64', 'getegid',
    177, 'process');
  AddSyscall(Result,
    'riscv64', 'gettid',
    178, 'process');
  AddSyscall(Result,
    'riscv64', 'sysinfo',
    179, 'process');
  AddSyscall(Result,
    'riscv64', 'mq_open',
    180, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'mq_unlink',
    181, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'mq_timedsend',
    182, 'network');
  AddSyscall(Result,
    'riscv64', 'mq_timedreceive',
    183, 'time');
  AddSyscall(Result,
    'riscv64', 'mq_notify',
    184, 'process');
  AddSyscall(Result,
    'riscv64', 'mq_getsetattr',
    185, 'process');
  AddSyscall(Result,
    'riscv64', 'msgget',
    186, 'ipc');
  AddSyscall(Result,
    'riscv64', 'msgctl',
    187, 'ipc');
  AddSyscall(Result,
    'riscv64', 'msgrcv',
    188, 'ipc');
  AddSyscall(Result,
    'riscv64', 'msgsnd',
    189, 'ipc');
  AddSyscall(Result,
    'riscv64', 'semget',
    190, 'ipc');
  AddSyscall(Result,
    'riscv64', 'semctl',
    191, 'ipc');
  AddSyscall(Result,
    'riscv64', 'semtimedop',
    192, 'time');
  AddSyscall(Result,
    'riscv64', 'semop',
    193, 'ipc');
  AddSyscall(Result,
    'riscv64', 'shmget',
    194, 'ipc');
  AddSyscall(Result,
    'riscv64', 'shmctl',
    195, 'ipc');
  AddSyscall(Result,
    'riscv64', 'shmat',
    196, 'ipc');
  AddSyscall(Result,
    'riscv64', 'shmdt',
    197, 'ipc');
  AddSyscall(Result,
    'riscv64', 'socket',
    198, 'network');
  AddSyscall(Result,
    'riscv64', 'socketpair',
    199, 'network');
  AddSyscall(Result,
    'riscv64', 'bind',
    200, 'network');
  AddSyscall(Result,
    'riscv64', 'listen',
    201, 'network');
  AddSyscall(Result,
    'riscv64', 'accept',
    202, 'network');
  AddSyscall(Result,
    'riscv64', 'connect',
    203, 'network');
  AddSyscall(Result,
    'riscv64', 'getsockname',
    204, 'process');
  AddSyscall(Result,
    'riscv64', 'getpeername',
    205, 'process');
  AddSyscall(Result,
    'riscv64', 'sendto',
    206, 'network');
  AddSyscall(Result,
    'riscv64', 'recvfrom',
    207, 'network');
  AddSyscall(Result,
    'riscv64', 'setsockopt',
    208, 'process');
  AddSyscall(Result,
    'riscv64', 'getsockopt',
    209, 'process');
  AddSyscall(Result,
    'riscv64', 'shutdown',
    210, 'process');
  AddSyscall(Result,
    'riscv64', 'sendmsg',
    211, 'network');
  AddSyscall(Result,
    'riscv64', 'recvmsg',
    212, 'network');
  AddSyscall(Result,
    'riscv64', 'readahead',
    213, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'brk',
    214, 'memory');
  AddSyscall(Result,
    'riscv64', 'munmap',
    215, 'memory');
  AddSyscall(Result,
    'riscv64', 'mremap',
    216, 'process');
  AddSyscall(Result,
    'riscv64', 'add_key',
    217, 'process');
  AddSyscall(Result,
    'riscv64', 'request_key',
    218, 'process');
  AddSyscall(Result,
    'riscv64', 'keyctl',
    219, 'process');
  AddSyscall(Result,
    'riscv64', 'clone',
    220, 'process');
  AddSyscall(Result,
    'riscv64', 'execve',
    221, 'process');
  AddSyscall(Result,
    'riscv64', 'swapon',
    224, 'process');
  AddSyscall(Result,
    'riscv64', 'swapoff',
    225, 'process');
  AddSyscall(Result,
    'riscv64', 'mprotect',
    226, 'memory');
  AddSyscall(Result,
    'riscv64', 'msync',
    227, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'mlock',
    228, 'process');
  AddSyscall(Result,
    'riscv64', 'munlock',
    229, 'process');
  AddSyscall(Result,
    'riscv64', 'mlockall',
    230, 'process');
  AddSyscall(Result,
    'riscv64', 'munlockall',
    231, 'process');
  AddSyscall(Result,
    'riscv64', 'mincore',
    232, 'process');
  AddSyscall(Result,
    'riscv64', 'madvise',
    233, 'memory');
  AddSyscall(Result,
    'riscv64', 'remap_file_pages',
    234, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'mbind',
    235, 'network');
  AddSyscall(Result,
    'riscv64', 'get_mempolicy',
    236, 'process');
  AddSyscall(Result,
    'riscv64', 'set_mempolicy',
    237, 'process');
  AddSyscall(Result,
    'riscv64', 'migrate_pages',
    238, 'process');
  AddSyscall(Result,
    'riscv64', 'move_pages',
    239, 'process');
  AddSyscall(Result,
    'riscv64', 'rt_tgsigqueueinfo',
    240, 'process');
  AddSyscall(Result,
    'riscv64', 'perf_event_open',
    241, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'accept4',
    242, 'network');
  AddSyscall(Result,
    'riscv64', 'recvmmsg',
    243, 'network');
  AddSyscall(Result,
    'riscv64', 'arch_specific_syscall',
    244, 'process');
  AddSyscall(Result,
    'riscv64', 'wait4',
    260, 'process');
  AddSyscall(Result,
    'riscv64', 'prlimit64',
    261, 'process');
  AddSyscall(Result,
    'riscv64', 'fanotify_init',
    262, 'process');
  AddSyscall(Result,
    'riscv64', 'fanotify_mark',
    263, 'process');
  AddSyscall(Result,
    'riscv64', 'name_to_handle_at',
    264, 'process');
  AddSyscall(Result,
    'riscv64', 'open_by_handle_at',
    265, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'clock_adjtime',
    266, 'time');
  AddSyscall(Result,
    'riscv64', 'syncfs',
    267, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'setns',
    268, 'process');
  AddSyscall(Result,
    'riscv64', 'sendmmsg',
    269, 'network');
  AddSyscall(Result,
    'riscv64', 'process_vm_readv',
    270, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'process_vm_writev',
    271, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'kcmp',
    272, 'process');
  AddSyscall(Result,
    'riscv64', 'finit_module',
    273, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_setattr',
    274, 'process');
  AddSyscall(Result,
    'riscv64', 'sched_getattr',
    275, 'process');
  AddSyscall(Result,
    'riscv64', 'renameat2',
    276, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'seccomp',
    277, 'process');
  AddSyscall(Result,
    'riscv64', 'getrandom',
    278, 'process');
  AddSyscall(Result,
    'riscv64', 'memfd_create',
    279, 'memory');
  AddSyscall(Result,
    'riscv64', 'bpf',
    280, 'process');
  AddSyscall(Result,
    'riscv64', 'execveat',
    281, 'process');
  AddSyscall(Result,
    'riscv64', 'userfaultfd',
    282, 'process');
  AddSyscall(Result,
    'riscv64', 'membarrier',
    283, 'process');
  AddSyscall(Result,
    'riscv64', 'mlock2',
    284, 'process');
  AddSyscall(Result,
    'riscv64', 'copy_file_range',
    285, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'preadv2',
    286, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pwritev2',
    287, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pkey_mprotect',
    288, 'memory');
  AddSyscall(Result,
    'riscv64', 'pkey_alloc',
    289, 'process');
  AddSyscall(Result,
    'riscv64', 'pkey_free',
    290, 'process');
  AddSyscall(Result,
    'riscv64', 'statx',
    291, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_pgetevents',
    292, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'rseq',
    293, 'process');
  AddSyscall(Result,
    'riscv64', 'kexec_file_load',
    294, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'clock_gettime64',
    403, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_settime64',
    404, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_adjtime64',
    405, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_getres_time64',
    406, 'time');
  AddSyscall(Result,
    'riscv64', 'clock_nanosleep_time64',
    407, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_gettime64',
    408, 'time');
  AddSyscall(Result,
    'riscv64', 'timer_settime64',
    409, 'time');
  AddSyscall(Result,
    'riscv64', 'timerfd_gettime64',
    410, 'time');
  AddSyscall(Result,
    'riscv64', 'timerfd_settime64',
    411, 'time');
  AddSyscall(Result,
    'riscv64', 'utimensat_time64',
    412, 'time');
  AddSyscall(Result,
    'riscv64', 'pselect6_time64',
    413, 'time');
  AddSyscall(Result,
    'riscv64', 'ppoll_time64',
    414, 'time');
  AddSyscall(Result,
    'riscv64', 'io_pgetevents_time64',
    416, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'recvmmsg_time64',
    417, 'network');
  AddSyscall(Result,
    'riscv64', 'mq_timedsend_time64',
    418, 'network');
  AddSyscall(Result,
    'riscv64', 'mq_timedreceive_time64',
    419, 'time');
  AddSyscall(Result,
    'riscv64', 'semtimedop_time64',
    420, 'time');
  AddSyscall(Result,
    'riscv64', 'rt_sigtimedwait_time64',
    421, 'time');
  AddSyscall(Result,
    'riscv64', 'futex_time64',
    422, 'time');
  AddSyscall(Result,
    'riscv64', 'sched_rr_get_interval_time64',
    423, 'time');
  AddSyscall(Result,
    'riscv64', 'pidfd_send_signal',
    424, 'network');
  AddSyscall(Result,
    'riscv64', 'io_uring_setup',
    425, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_uring_enter',
    426, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'io_uring_register',
    427, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'open_tree',
    428, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'move_mount',
    429, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fsopen',
    430, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fsconfig',
    431, 'process');
  AddSyscall(Result,
    'riscv64', 'fsmount',
    432, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fspick',
    433, 'process');
  AddSyscall(Result,
    'riscv64', 'pidfd_open',
    434, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'clone3',
    435, 'process');
  AddSyscall(Result,
    'riscv64', 'close_range',
    436, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'openat2',
    437, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'pidfd_getfd',
    438, 'process');
  AddSyscall(Result,
    'riscv64', 'faccessat2',
    439, 'process');
  AddSyscall(Result,
    'riscv64', 'process_madvise',
    440, 'memory');
  AddSyscall(Result,
    'riscv64', 'epoll_pwait2',
    441, 'ipc');
  AddSyscall(Result,
    'riscv64', 'mount_setattr',
    442, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'quotactl_fd',
    443, 'process');
  AddSyscall(Result,
    'riscv64', 'landlock_create_ruleset',
    444, 'process');
  AddSyscall(Result,
    'riscv64', 'landlock_add_rule',
    445, 'process');
  AddSyscall(Result,
    'riscv64', 'landlock_restrict_self',
    446, 'process');
  AddSyscall(Result,
    'riscv64', 'memfd_secret',
    447, 'memory');
  AddSyscall(Result,
    'riscv64', 'process_mrelease',
    448, 'process');
  AddSyscall(Result,
    'riscv64', 'futex_waitv',
    449, 'ipc');
  AddSyscall(Result,
    'riscv64', 'set_mempolicy_home_node',
    450, 'process');
  AddSyscall(Result,
    'riscv64', 'cachestat',
    451, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'fchmodat2',
    452, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'map_shadow_stack',
    453, 'process');
  AddSyscall(Result,
    'riscv64', 'futex_wake',
    454, 'ipc');
  AddSyscall(Result,
    'riscv64', 'futex_wait',
    455, 'ipc');
  AddSyscall(Result,
    'riscv64', 'futex_requeue',
    456, 'ipc');
  AddSyscall(Result,
    'riscv64', 'statmount',
    457, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'listmount',
    458, 'filesystem');
  AddSyscall(Result,
    'riscv64', 'lsm_get_self_attr',
    459, 'process');
  AddSyscall(Result,
    'riscv64', 'lsm_set_self_attr',
    460, 'process');
  AddSyscall(Result,
    'riscv64', 'lsm_list_modules',
    461, 'process');
  AddSyscall(Result,
    'riscv64', 'mseal',
    462, 'process');
  AddSyscall(Result,
    'riscv64', 'syscalls',
    463, 'process');
end;

function FindLinuxSyscall(const ACatalog: TLinuxSyscallDescriptorArray;
  const AArchitecture, AName: string;
  out ADescriptor: TLinuxSyscallDescriptor): Boolean;
var I: LongInt;
begin
  for I := 0 to High(ACatalog) do
    if (ACatalog[I].Architecture = AArchitecture) and
      (ACatalog[I].Name = AName) then
    begin ADescriptor := ACatalog[I]; Exit(True); end;
  ADescriptor.Architecture := ''; ADescriptor.Name := '';
  ADescriptor.Number := -1; ADescriptor.Category := ''; Result := False;
end;

function LinuxSyscallCatalogSummary(
  const ACatalog: TLinuxSyscallDescriptorArray): string;
var I, X64, A64, RV: LongInt;
begin
  X64 := 0; A64 := 0; RV := 0;
  for I := 0 to High(ACatalog) do
    if ACatalog[I].Architecture = 'x86_64' then Inc(X64)
    else if ACatalog[I].Architecture = 'aarch64' then Inc(A64)
    else if ACatalog[I].Architecture = 'riscv64' then Inc(RV);
  Result := Format('%d Linux syscall descriptors (x86_64=%d, aarch64=%d, riscv64=%d)',
    [Length(ACatalog), X64, A64, RV]);
end;

end.
