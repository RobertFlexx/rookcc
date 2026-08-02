#include "rcc.h"

long fibonacci(long n)
{
    if (n < 2)
        return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(void)
{
    long i = 0;
    while (i < 10)
    {
        print_int(fibonacci(i));
        i++;
    }
    return 0;
}
