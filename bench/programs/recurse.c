/* Recursion and call overhead: fib, ackermann-lite, and a quicksort. */
#include <stdio.h>

#define NSORT 40000
#define SORTREPS 60

static int data[NSORT];

static long fib(int n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

static int gcd(int a, int b) {
    if (b == 0) return a;
    return gcd(b, a % b);
}

static void quicksort(int *v, int lo, int hi) {
    int i, j, pivot, tmp;
    if (lo >= hi) return;
    pivot = v[(lo + hi) / 2];
    i = lo;
    j = hi;
    while (i <= j) {
        while (v[i] < pivot) i++;
        while (v[j] > pivot) j--;
        if (i <= j) {
            tmp = v[i]; v[i] = v[j]; v[j] = tmp;
            i++; j--;
        }
    }
    quicksort(v, lo, j);
    quicksort(v, i, hi);
}

int main(void) {
    int r, i;
    long acc = 0;
    acc += fib(27);
    for (i = 1; i < 4000; i++) acc += gcd(i * 7919, i + 104729);
    for (r = 0; r < SORTREPS; r++) {
        unsigned int seed = 12345u + (unsigned int)r;
        for (i = 0; i < NSORT; i++) {
            seed = seed * 1103515245u + 12345u;
            data[i] = (int)((seed >> 16) & 0x7fff);
        }
        quicksort(data, 0, NSORT - 1);
        for (i = 0; i < NSORT; i += 512) acc += data[i];
        if (data[0] > data[NSORT - 1]) acc = -1;
    }
    printf("recurse %ld\n", acc);
    return 0;
}
