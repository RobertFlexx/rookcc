/* Integer widths, signedness, conversions, and every comparison operator. */
#include <stdio.h>

static signed char sc = -100;
static unsigned char uc = 200;
static short sh = -30000;
static unsigned short ush = 60000;
static int si = -2000000000;
static unsigned int ui = 4000000000u;
static long sl = -9000000000000000000L;
static unsigned long ul = 18000000000000000000UL;

static void widths(void) {
    printf("w %d %d %d %d %d %d %d %d\n",
           (int)sizeof(char), (int)sizeof(short), (int)sizeof(int),
           (int)sizeof(long), (int)sizeof(long long), (int)sizeof(void *),
           (int)sizeof(float), (int)sizeof(double));
}

static void conversions(void) {
    printf("c %d %d %d %d %d %u %ld %lu\n",
           (int)sc, (int)uc, (int)sh, (int)ush, si, ui, sl, ul);
    printf("n %d %d %d %d\n", (int)(char)300, (int)(signed char)-300,
           (int)(short)70000, (int)(unsigned short)-1);
    printf("p %d %u %ld %lu\n", (int)uc + (int)sc, ui + 1u, sl + 1, ul + 1);
    printf("t %d %d %d\n", (int)(sc < uc), (int)(si < 0), (int)(ui > 0));
}

static void comparisons(void) {
    int a = -5, b = 3;
    unsigned int ua = 5u, ub = 3u;
    printf("s %d%d%d%d%d%d\n", a < b, a <= b, a > b, a >= b, a == b, a != b);
    printf("u %d%d%d%d%d%d\n", ua < ub, ua <= ub, ua > ub, ua >= ub,
           ua == ub, ua != ub);
    printf("m %d%d%d%d\n", -1 < 1u, (long)-1 < 1L, 0u <= 0u, -1 != 0);
}

static void arithmetic(void) {
    int a = 17, b = -5;
    printf("a %d %d %d %d %d\n", a + b, a - b, a * b, a / b, a % b);
    printf("b %d %d %d %d %d\n", a & b, a | b, a ^ b, a << 2, a >> 2);
    printf("g %d %d\n", -a >> 1, (int)((unsigned)-a >> 1));
    printf("h %d %d %d\n", ~a, -a, !a);
}

static void shortcircuit(void) {
    int calls = 0;
    int i;
    for (i = 0; i < 4; i++) {
        int lhs = i & 1;
        int rhs = (i >> 1) & 1;
        if (lhs && (++calls, rhs)) printf("and%d ", i);
        if (lhs || (++calls, rhs)) printf("or%d ", i);
    }
    printf("calls=%d\n", calls);
}

int main(void) {
    widths();
    conversions();
    comparisons();
    arithmetic();
    shortcircuit();
    return 0;
}
