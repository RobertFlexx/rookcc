/* Freestanding: loops, switch, goto, break/continue, nested control flow. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

static int classify(int n) {
    switch (n & 7) {
        case 0: return 100;
        case 1:
        case 2: return 200;
        case 3: return 300;
        case 7: return 700;
        default: return -1;
    }
}

int main(void) {
    int i, j, total = 0;

    for (i = 0; i < 20; i++) mix(classify(i));

    for (i = 0; i < 12; i++) {
        if (i % 3 == 0) continue;
        if (i == 10) break;
        total += i;
    }
    mix(total);

    i = 0; total = 0;
    while (i < 30) { total += i * 2; i += 3; }
    mix(total);

    i = 0; total = 0;
    do { total += i; i++; } while (i < 9);
    mix(total);

    total = 0;
    for (i = 0; i < 7; i++)
        for (j = 0; j < 7; j++) {
            if (j > i) break;
            total += i * j;
        }
    mix(total);

    i = 0; total = 0;
again:
    total += i * i;
    i++;
    if (i < 8) goto again;
    mix(total);

    {
        int fall = 0, n;
        for (n = 0; n < 6; n++)
            switch (n) {
                case 0: fall += 1;
                case 1: fall += 10; break;
                case 2: fall += 100;
                case 3: fall += 1000; break;
                default: fall += 10000;
            }
        mix(fall);
    }
    return checksum & 0xff;
}
