/* Zero-initialized vs initialized globals: exercises .bss and .data layout. */
#include <stdio.h>

static int zero_int;
static long zero_long;
static char zero_array[4096];
static int zero_matrix[16][16];
static double zero_double;
static int *zero_pointer;

static int init_int = 42;
static long init_long = -1234567890123L;
static char init_array[8] = "abc";
static int init_matrix[2][2] = {{1, 2}, {3, 4}};
static double init_double = 2.5;

int shared_zero;
int shared_init = 7;

static int all_zero_explicit[4] = {0, 0, 0, 0};

static long checksum(const char *p, int n) {
    long acc = 0;
    int i;
    for (i = 0; i < n; i++) acc += (unsigned char)p[i] * (i + 1);
    return acc;
}

int main(void) {
    int i, j;
    long acc = 0;

    printf("z %d %ld %d %d %.1f %d\n", zero_int, zero_long, zero_array[0],
           zero_matrix[15][15], zero_double, zero_pointer == 0);
    printf("i %d %ld %s %d %.1f\n", init_int, init_long, init_array,
           init_matrix[1][1], init_double);
    printf("s %d %d\n", shared_zero, shared_init);
    printf("e %d %d\n", all_zero_explicit[0], all_zero_explicit[3]);
    printf("k %ld\n", checksum(zero_array, 4096));

    for (i = 0; i < 4096; i++) zero_array[i] = (char)(i & 0x7f);
    for (i = 0; i < 16; i++)
        for (j = 0; j < 16; j++)
            zero_matrix[i][j] = i * 16 + j;
    for (i = 0; i < 16; i++) acc += zero_matrix[i][i];
    printf("w %ld %ld\n", checksum(zero_array, 4096), acc);

    zero_pointer = &zero_int;
    *zero_pointer = 99;
    printf("p %d %d\n", zero_int, *zero_pointer);
    return 0;
}
