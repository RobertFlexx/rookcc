/* Floating point arithmetic, comparisons and integer interconversion. */
#include <stdio.h>

static double dvals[6] = {0.0, 1.5, -2.25, 100.125, -0.5, 3.0};
static float fvals[4] = {1.0f, -1.5f, 2.75f, 0.25f};

static double accumulate(const double *v, int n) {
    double acc = 0;
    int i;
    for (i = 0; i < n; i++) acc += v[i] * (i + 1);
    return acc;
}

int main(void) {
    double a = 7.5, b = 2.5;
    float f = 1.25f;
    int i;

    printf("ar %.4f %.4f %.4f %.4f\n", a + b, a - b, a * b, a / b);
    printf("cm %d%d%d%d%d%d\n", a < b, a <= b, a > b, a >= b, a == b, a != b);
    printf("ac %.4f\n", accumulate(dvals, 6));

    for (i = 0; i < 4; i++) printf("f%d %.4f ", i, (double)(fvals[i] * 2.0f));
    printf("\n");

    printf("i2d %.4f %.4f %.4f\n", (double)7, (double)-3, (double)1000000);
    printf("d2i %d %d %d %d\n", (int)1.9, (int)-1.9, (int)0.5, (int)-0.5);
    printf("f2d %.4f %.4f\n", (double)f, (double)(f + 0.25f));
    printf("mix %.4f %.4f\n", a + 3, a * 2 - 1);

    {
        double acc = 0;
        for (i = 1; i <= 100; i++) acc += 1.0 / (double)i;
        printf("hs %.6f\n", acc);
    }
    {
        double x = 1.0;
        int n = 0;
        while (x > 0.001) { x /= 2.0; n++; }
        printf("hv %d %.6f\n", n, x);
    }
    {
        float sum = 0.0f;
        for (i = 0; i < 10; i++) sum += (float)i * 0.5f;
        printf("fs %.4f\n", (double)sum);
    }
    return 0;
}
