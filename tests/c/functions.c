/* Calls, recursion, varargs, statics, and many-argument signatures. */
#include <stdarg.h>
#include <stdio.h>

static int depth_counter;

static long ackermann_lite(int m, int n) {
    depth_counter++;
    if (m == 0) return n + 1;
    if (n == 0) return ackermann_lite(m - 1, 1);
    return ackermann_lite(m - 1, (int)ackermann_lite(m, n - 1));
}

static int counter(void) {
    static int n = 0;
    return ++n;
}

/* A static local keeps its value between calls, so constant propagation must
   not assume the initializer still holds on re-entry. */
static int table[4] = {9, 8, 7, 6};

static int cycle(void) {
    static int index = 0;
    return table[index++ % 4];
}

static int loop_static(void) {
    int k, total = 0;
    for (k = 0; k < 3; k++) {
        static int inner = 0;
        inner++;
        total += inner;
    }
    return total;
}

/* An operand with side effects must be evaluated once even when the right
   side is a constant the backend cannot fold into an immediate. */
static int ticks;

static int tick(void) { return ++ticks; }

static int many(int a, int b, int c, int d, int e, int f, int g, int h,
                int i, int j) {
    return a * 1 + b * 2 + c * 3 + d * 4 + e * 5 + f * 6 + g * 7 + h * 8 +
           i * 9 + j * 10;
}

static long total(int count, ...) {
    va_list ap;
    long acc = 0;
    int i;
    va_start(ap, count);
    for (i = 0; i < count; i++) acc += va_arg(ap, int);
    va_end(ap);
    return acc;
}

static double mixed(int n, ...) {
    va_list ap;
    double acc = 0;
    int i;
    va_start(ap, n);
    for (i = 0; i < n; i++) acc += va_arg(ap, double);
    va_end(ap);
    return acc;
}

static int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

int main(void) {
    int i;
    long ack = ackermann_lite(2, 3);
    printf("ack %ld %d\n", ack, depth_counter);
    printf("fib");
    for (i = 0; i < 12; i++) printf(" %d", fib(i));
    printf("\n");
    printf("cnt");
    for (i = 0; i < 4; i++) printf(" %d", counter());
    printf("\n");
    printf("many %d\n", many(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
    printf("va %ld %ld\n", total(5, 1, 2, 3, 4, 5),
           total(3, 100, 200, 300));
    printf("vd %.2f\n", mixed(3, 1.5, 2.25, 3.125));
    {
        int first = counter();
        int second = counter();
        printf("ord %d\n", many(first, second, 1, 1, 1, 1, 1, 1, 1, 1));
    }
    printf("cyc");
    for (i = 0; i < 6; i++) printf(" %d", cycle());
    printf("\n");
    {
        int a = loop_static();
        int b = loop_static();
        printf("lst %d %d\n", a, b);
    }
    printf("sfx");
    for (i = 0; i < 6; i++) printf(" %d", tick() % 5);
    printf(" %d", ticks);
    for (i = 0; i < 4; i++) printf(" %d", tick() / 3);
    printf(" %d\n", ticks);
    return 0;
}
