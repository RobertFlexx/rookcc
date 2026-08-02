/* Multidimensional arrays, initializers, brace elision, and decay. */
#include <stdio.h>

static int g1[5] = {1, 2, 3};
static int g2[2][3] = {{1, 2, 3}, {4, 5, 6}};
static int g2flat[2][3] = {1, 2, 3, 4, 5, 6};
static int g3[2][2][2] = {{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}};
static char names[3][8] = {"ab", "cde", "f"};
static char blank[4][4];

static int sum2(int (*m)[3], int rows) {
    int i, j, total = 0;
    for (i = 0; i < rows; i++)
        for (j = 0; j < 3; j++)
            total += m[i][j];
    return total;
}

int main(void) {
    int l1[4] = {9, 8};
    int l2[2][2] = {{1, 2}, {3, 4}};
    int lflat[2][2] = {5, 6, 7, 8};
    int i, j, k;
    long acc = 0;

    printf("sz %d %d %d %d %d\n", (int)sizeof(g1), (int)sizeof(g2),
           (int)sizeof(g2[0]), (int)sizeof(g3), (int)sizeof(names));
    printf("g1 %d %d %d %d %d\n", g1[0], g1[1], g1[2], g1[3], g1[4]);
    printf("g2 %d %d %d %d\n", g2[0][0], g2[0][2], g2[1][0], g2[1][2]);
    printf("gf %d %d %d %d\n", g2flat[0][0], g2flat[0][2], g2flat[1][0],
           g2flat[1][2]);
    printf("l1 %d %d %d %d\n", l1[0], l1[1], l1[2], l1[3]);
    printf("l2 %d %d %d %d\n", l2[0][0], l2[0][1], l2[1][0], l2[1][1]);
    printf("lf %d %d %d %d\n", lflat[0][0], lflat[0][1], lflat[1][0],
           lflat[1][1]);
    printf("nm %s %s %s\n", names[0], names[1], names[2]);
    printf("bl %d %d\n", blank[0][0], blank[3][3]);

    for (i = 0; i < 2; i++)
        for (j = 0; j < 2; j++)
            for (k = 0; k < 2; k++)
                acc = acc * 10 + g3[i][j][k];
    printf("g3 %ld\n", acc);
    printf("fn %d\n", sum2(g2, 2));

    {
        int *p = g1;
        int (*row)[3] = g2;
        printf("pt %d %d %d %d\n", *p, *(p + 2), (*row)[1], (*(row + 1))[2]);
        printf("df %ld %ld\n", (long)(&g1[4] - &g1[0]),
               (long)((char *)&g2[1][0] - (char *)&g2[0][0]));
    }

    {
        int dyn[3][4];
        for (i = 0; i < 3; i++)
            for (j = 0; j < 4; j++)
                dyn[i][j] = i * 4 + j;
        acc = 0;
        for (i = 0; i < 3; i++)
            for (j = 0; j < 4; j++)
                acc += dyn[i][j] * (i + 1);
        printf("dy %ld\n", acc);
    }
    return 0;
}
