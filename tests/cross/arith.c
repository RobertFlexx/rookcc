/* Freestanding: integer arithmetic, conversions and comparisons.
   Every cross program returns a checksum in 0..255 so it can be compared
   across architectures through the process exit status. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

int main(void) {
    int a = 17, b = -5;
    unsigned int ua = 4000000000u, ub = 7;
    long la = 1234567890123L;
    short s = -30000;
    unsigned char uc = 250;
    signed char sc = -100;

    mix(a + b); mix(a - b); mix(a * b); mix(a / b); mix(a % b);
    mix(a & b); mix(a | b); mix(a ^ b); mix(a << 3); mix(a >> 2);
    mix(~a); mix(-a); mix(!a); mix(!0);
    mix(ua / ub); mix(ua % ub); mix((int)(ua >> 3));
    mix(la); mix(la / 1000); mix(la % 97);
    mix(s); mix((short)(s - 10000)); mix(uc); mix((unsigned char)(uc + 10));
    mix(sc); mix((signed char)(sc - 100));
    mix(a < b); mix(a <= b); mix(a > b); mix(a >= b); mix(a == b); mix(a != b);
    mix(ua < ub); mix(ua > ub);
    mix((long)a * (long)b);
    mix((int)(la >> 20));
    return checksum & 0xff;
}
