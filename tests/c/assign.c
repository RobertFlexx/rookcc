/* Compound assignment, increment/decrement, and evaluation of lvalues. */
#include <stdio.h>

static int g;
static int arr[6];
static struct { int v; int w; } rec;

static int side(int *slot, int value) {
    *slot += 1;
    return value;
}

int main(void) {
    int a = 10, b = 3;
    int i, calls = 0;
    unsigned char uc = 250;
    short sh = 30000;

    a += b; printf("1 %d\n", a);
    a -= 1; printf("2 %d\n", a);
    a *= 3; printf("3 %d\n", a);
    a /= 4; printf("4 %d\n", a);
    a %= 7; printf("5 %d\n", a);
    a <<= 4; printf("6 %d\n", a);
    a >>= 2; printf("7 %d\n", a);
    a |= 0x55; printf("8 %d\n", a);
    a &= 0x3c; printf("9 %d\n", a);
    a ^= 0xff; printf("10 %d\n", a);

    g = 5;
    g += 7; g *= 2;
    printf("g %d\n", g);

    for (i = 0; i < 6; i++) arr[i] = i;
    arr[2] += 10;
    arr[3] *= 4;
    arr[4]++;
    --arr[5];
    printf("ar %d %d %d %d %d %d\n", arr[0], arr[1], arr[2], arr[3], arr[4],
           arr[5]);

    rec.v = 3; rec.w = 4;
    rec.v += rec.w;
    rec.w -= 1;
    printf("rc %d %d\n", rec.v, rec.w);

    i = 5;
    printf("ix %d", i++);
    printf(" %d", i);
    printf(" %d", ++i);
    printf(" %d\n", i);
    i = 5;
    printf("dx %d", i--);
    printf(" %d", i);
    printf(" %d", --i);
    printf(" %d\n", i);

    uc += 10;
    sh += 10000;
    printf("ov %d %d\n", (int)uc, (int)sh);

    {
        int n = 0;
        arr[side(&calls, 1)] = side(&calls, 100);
        n = arr[1];
        printf("sd %d %d\n", n, calls);
    }
    {
        int x = 1, y = 2, z = 3;
        x = y = z = 9;
        printf("ch %d %d %d\n", x, y, z);
    }
    {
        int v = 7;
        int *pp = &v;
        *pp += 3;
        (*pp)++;
        printf("pp %d\n", v);
    }
    return 0;
}
