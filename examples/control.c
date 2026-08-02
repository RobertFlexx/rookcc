#include "rcc.h"

int main(void)
{
    long sum = 0;
    long i;
    for (i = 0; i < 100; i++)
        sum += i;
    print_int(sum);
    return 0;
}
