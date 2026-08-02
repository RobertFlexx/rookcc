/* String and pointer heavy workload: char pointers, comparisons, copies. */
#include <stdio.h>
#include <string.h>

#define SLOTS 512
#define ROUNDS 4000

static char pool[SLOTS][40];
static char scratch[64];

static unsigned int hash_str(const char *s) {
    unsigned int h = 5381u;
    while (*s) { h = h * 33u + (unsigned char)*s; s++; }
    return h;
}

static void make_name(char *dst, int n) {
    int i = 0;
    dst[i++] = 'k';
    dst[i++] = 'e';
    dst[i++] = 'y';
    if (n >= 100) dst[i++] = (char)('0' + (n / 100) % 10);
    if (n >= 10)  dst[i++] = (char)('0' + (n / 10) % 10);
    dst[i++] = (char)('0' + n % 10);
    dst[i] = 0;
}

int main(void) {
    int r, i;
    unsigned int total = 0;
    long matches = 0;
    for (i = 0; i < SLOTS; i++) make_name(pool[i], i);
    for (r = 0; r < ROUNDS; r++) {
        for (i = 0; i < SLOTS; i++) {
            total += hash_str(pool[i]);
            if (strlen(pool[i]) > 4) matches++;
        }
        make_name(scratch, r % SLOTS);
        for (i = 0; i < SLOTS; i++)
            if (strcmp(scratch, pool[i]) == 0) matches += 3;
    }
    printf("strings %u %ld\n", total, matches);
    return 0;
}
