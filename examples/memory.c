#include <stdlib.h>
#include "rcc.h"

int main(void)
{
    long *values = (long *)malloc(16);
    values[0] = 40;
    values[1] = 2;
    print_int(values[0] + values[1]);
    free(values);
    return 0;
}
