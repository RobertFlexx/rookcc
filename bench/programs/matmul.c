/* Integer matrix multiply: nested loops over 2-D arrays. */
#include <stdio.h>

#define N 110

static int a[N][N], b[N][N], c[N][N];

int main(void) {
    int i, j, k, rep;
    for (i = 0; i < N; i++)
        for (j = 0; j < N; j++) {
            a[i][j] = (i * 3 + j * 7) % 17;
            b[i][j] = (i * 5 + j * 11) % 13;
        }
    for (rep = 0; rep < 30; rep++) {
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++) {
                int sum = 0;
                for (k = 0; k < N; k++)
                    sum += a[i][k] * b[k][j];
                c[i][j] = sum;
            }
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                a[i][j] = (c[i][j] + i) % 19;
    }
    {
        long checksum = 0;
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                checksum += (long)c[i][j] * ((i ^ j) + 1);
        printf("matmul %ld\n", checksum);
    }
    return 0;
}
