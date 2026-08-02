/* Prime sieve plus bit manipulation: byte arrays and tight while loops. */
#include <stdio.h>

#define LIMIT 400000
#define ROUNDS 40

static unsigned char flags[LIMIT + 1];

static int popcount32(unsigned int v) {
    int n = 0;
    while (v) { v &= v - 1; n++; }
    return n;
}

int main(void) {
    int round, i, j, count = 0;
    unsigned int hash = 2166136261u;
    for (round = 0; round < ROUNDS; round++) {
        count = 0;
        for (i = 0; i <= LIMIT; i++) flags[i] = 1;
        flags[0] = 0;
        flags[1] = 0;
        for (i = 2; (long)i * i <= LIMIT; i++)
            if (flags[i])
                for (j = i * i; j <= LIMIT; j += i)
                    flags[j] = 0;
        for (i = 2; i <= LIMIT; i++)
            if (flags[i]) {
                count++;
                hash = (hash ^ (unsigned int)i) * 16777619u;
            }
    }
    printf("sieve %d %u %d\n", count, hash, popcount32(hash));
    return 0;
}
