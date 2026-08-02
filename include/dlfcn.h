#ifndef RCC_DLFCN_H
#define RCC_DLFCN_H

#include <rcc/features.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RTLD_LAZY 0x00001
#define RTLD_NOW 0x00002
#define RTLD_BINDING_MASK 0x00003
#define RTLD_NOLOAD 0x00004
#define RTLD_DEEPBIND 0x00008
#define RTLD_GLOBAL 0x00100
#define RTLD_LOCAL 0
#define RTLD_NODELETE 0x01000

#define RTLD_NEXT ((void *)-1L)
#define RTLD_DEFAULT ((void *)0)

void *dlopen(const char *file_name, int mode);
int dlclose(void *handle);
void *dlsym(void *handle, const char *symbol_name);
char *dlerror(void);

#if defined(__RCC_USE_GNU)
typedef struct {
  const char *dli_fname;
  void *dli_fbase;
  const char *dli_sname;
  void *dli_saddr;
} Dl_info;

int dladdr(const void *address, Dl_info *information);
#endif

#ifdef __cplusplus
}
#endif

#endif
