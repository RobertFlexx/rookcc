/* Freestanding: string literals, char pointers and byte-level loops. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

static const char *words[4] = {"alpha", "beta", "gamma", "delta"};
static char buffer[64];

static int length(const char *s) {
    int n = 0;
    while (*s) { n++; s++; }
    return n;
}

static void copy(char *dst, const char *src) {
    while (*src) { *dst = *src; dst++; src++; }
    *dst = 0;
}

static int compare(const char *a, const char *b) {
    while (*a && (*a == *b)) { a++; b++; }
    return (int)((unsigned char)*a) - (int)((unsigned char)*b);
}

static unsigned hash(const char *s) {
    unsigned h = 2166136261u;
    while (*s) { h = (h ^ (unsigned char)*s) * 16777619u; s++; }
    return h;
}

int main(void) {
    int i;

    for (i = 0; i < 4; i++) {
        mix(length(words[i]));
        mix((int)(hash(words[i]) & 0xffff));
        mix(words[i][0]);
    }
    copy(buffer, "the quick brown fox");
    mix(length(buffer));
    mix(buffer[4]);
    mix(compare(buffer, "the quick brown fox"));
    mix(compare(buffer, "the quick brown fpx") < 0);

    for (i = 0; buffer[i]; i++)
        if (buffer[i] >= 'a' && buffer[i] <= 'z') buffer[i] = (char)(buffer[i] - 32);
    mix(length(buffer));
    for (i = 0; i < 19; i += 4) mix(buffer[i]);

    {
        const char *p = "0123456789";
        int total = 0;
        while (*p) { total += *p - '0'; p++; }
        mix(total);
    }
    return checksum & 0xff;
}
