/* Loops, switch, goto, break/continue, and nested control flow. */
#include <stdio.h>

static int collatz(int n) {
    int steps = 0;
    while (n != 1) {
        if (n % 2 == 0) n /= 2;
        else n = 3 * n + 1;
        steps++;
        if (steps > 1000) break;
    }
    return steps;
}

static const char *classify(int n) {
    switch (n) {
        case 0: return "zero";
        case 1:
        case 2: return "small";
        case 10: return "ten";
        default: break;
    }
    if (n < 0) return "negative";
    return "big";
}

int main(void) {
    int i, j, total = 0;

    for (i = 0; i < 20; i++) total += collatz(i + 1);
    printf("collatz %d\n", total);

    for (i = -2; i <= 11; i++) printf("%s ", classify(i));
    printf("\n");

    total = 0;
    for (i = 0; i < 10; i++) {
        if (i % 3 == 0) continue;
        if (i == 8) break;
        total += i;
    }
    printf("skip %d\n", total);

    total = 0;
    i = 0;
    do { total += i; i++; } while (i < 5);
    printf("do %d\n", total);

    total = 0;
    for (i = 0; i < 5; i++)
        for (j = 0; j < 5; j++) {
            if (j > i) break;
            total += i * j;
        }
    printf("nest %d\n", total);

    i = 0;
    total = 0;
top:
    total += i;
    i++;
    if (i < 6) goto top;
    printf("goto %d\n", total);

    {
        int fall = 0, n;
        for (n = 0; n < 5; n++) {
            switch (n) {
                case 0: fall += 1;
                case 1: fall += 10; break;
                case 2: fall += 100;
                case 3: fall += 1000; break;
                default: fall += 10000;
            }
        }
        printf("fall %d\n", fall);
    }
    return 0;
}
