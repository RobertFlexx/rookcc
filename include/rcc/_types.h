#ifndef _RCC_INTERNAL_TYPES_H
#define _RCC_INTERNAL_TYPES_H 1

#include <rcc/features.h>

#ifndef __RCC_SIZE_T_DEFINED
#define __RCC_SIZE_T_DEFINED 1
typedef unsigned long size_t;
#endif

#ifndef __RCC_SSIZE_T_DEFINED
#define __RCC_SSIZE_T_DEFINED 1
typedef long ssize_t;
#endif

#ifndef __RCC_PTRDIFF_T_DEFINED
#define __RCC_PTRDIFF_T_DEFINED 1
typedef long ptrdiff_t;
#endif

#ifndef __RCC_INTPTR_T_DEFINED
#define __RCC_INTPTR_T_DEFINED 1
typedef long intptr_t;
typedef unsigned long uintptr_t;
#endif

#ifndef __RCC_OFF_T_DEFINED
#define __RCC_OFF_T_DEFINED 1
typedef long off_t;
#endif

#ifndef __RCC_TIME_T_DEFINED
#define __RCC_TIME_T_DEFINED 1
typedef long time_t;
#endif

#ifndef __RCC_PID_T_DEFINED
#define __RCC_PID_T_DEFINED 1
typedef int pid_t;
#endif

#ifndef __RCC_MODE_T_DEFINED
#define __RCC_MODE_T_DEFINED 1
typedef unsigned int mode_t;
#endif

#ifndef __RCC_UID_GID_T_DEFINED
#define __RCC_UID_GID_T_DEFINED 1
typedef unsigned int uid_t;
typedef unsigned int gid_t;
#endif

#endif
