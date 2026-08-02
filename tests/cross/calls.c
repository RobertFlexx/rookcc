/* Freestanding: recursion, many arguments, function pointers, static locals. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

static int fib(int n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }

static int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }

static long ack(int m, int n) {
    if (m == 0) return n + 1;
    if (n == 0) return ack(m - 1, 1);
    return ack(m - 1, (int)ack(m, n - 1));
}

static int many(int a, int b, int c, int d, int e, int f, int g, int h) {
    return a + b * 2 + c * 3 + d * 4 + e * 5 + f * 6 + g * 7 + h * 8;
}

static int wide(int a, int b, int c, int d, int e, int f, int g, int h,
                int i, int j, int k, int l) {
    return a + b + c + d + e + f + g + h + i * 10 + j * 100 + k * 1000 + l;
}

static int counter(void) { static int n; return ++n; }

static int twice(int x) { return x * 2; }
static int square(int x) { return x * x; }
static int negate(int x) { return -x; }

typedef int (*unop)(int);

static int apply(unop f, int v) { return f(v); }

int main(void) {
    int i;
    unop table[3];

    for (i = 0; i < 14; i++) mix(fib(i));
    for (i = 1; i < 20; i++) mix(gcd(i * 7, i + 91));
    mix(ack(2, 3));
    mix(many(1, 2, 3, 4, 5, 6, 7, 8));
    mix(wide(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12));
    for (i = 0; i < 5; i++) mix(counter());

    table[0] = twice; table[1] = square; table[2] = negate;
    for (i = 0; i < 3; i++) mix(apply(table[i], 6));
    for (i = 0; i < 3; i++) mix(table[i](i + 2));
    return checksum & 0xff;
}
