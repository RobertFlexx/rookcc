#include "rcc.h"

#define ANSWER 42
#define ENABLED 1

int main(void)
{
#if defined(ENABLED) && ENABLED
    print_int(ANSWER);
#elif defined(OTHER)
    print_int(7);
#else
    print_int(0);
#endif
    return 0;
}
