/* Freestanding: static function-pointer tables, indirect calls and the
   argument forms that cross the register/stack boundary. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }
static int mul(int a, int b) { return a * b; }

typedef int (*binop)(int, int);

static binop table[3] = {add, sub, mul};

static const char *names[3] = {"add", "sub", "mul"};

static int wide(int a, int b, int c, int d, int e, int f, int g, int h,
                int i, int j, int k, int l) {
    return a + b * 2 + c * 3 + d * 4 + e * 5 + f * 6 + g * 7 + h * 8 +
           i * 9 + j * 10 + k * 11 + l * 12;
}

static long widelong(long a, long b, long c, long d, long e, long f,
                     long g, long h, long i, long j) {
    return a - b + c - d + e - f + g - h + i - j;
}

static int length(const char *s) {
    int n = 0;
    while (*s) { n++; s++; }
    return n;
}

int main(void) {
    int i, j;

    for (i = 0; i < 3; i++) {
        mix(table[i](17, 5));
        mix(length(names[i]));
        mix(names[i][0]);
    }
    for (i = 0; i < 3; i++)
        for (j = 0; j < 3; j++)
            mix(table[i](j * 3, j + 1));

    mix(wide(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12));
    mix(wide(-1, 2, -3, 4, -5, 6, -7, 8, -9, 10, -11, 12));
    mix(widelong(100, 20, 3, 4, 5, 6, 7, 8, 9, 10));

    {
        binop chosen = table[2];
        mix(chosen(6, 7));
        chosen = table[0];
        mix(chosen(6, 7));
    }
    return checksum & 0xff;
}
