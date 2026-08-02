/* Freestanding: address-of, dereference, arrays, multidimensional indexing. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

static int grid[6][5];
static long flat[32];
static char bytes[16];

static int sum_row(int *row, int n) {
    int i, s = 0;
    for (i = 0; i < n; i++) s += row[i];
    return s;
}

int main(void) {
    int i, j;
    int local[8];
    int value = 42;
    int *p = &value;
    int **pp = &p;

    mix(*p);
    *p = 7;
    mix(value);
    **pp = 9;
    mix(value);

    for (i = 0; i < 8; i++) local[i] = i * i;
    for (i = 0; i < 8; i++) mix(local[i]);
    mix(sum_row(local, 8));

    for (i = 0; i < 6; i++)
        for (j = 0; j < 5; j++)
            grid[i][j] = i * 5 + j;
    for (i = 0; i < 6; i++) mix(sum_row(grid[i], 5));
    mix(grid[3][4]);
    mix(grid[5][0]);

    for (i = 0; i < 32; i++) flat[i] = (long)i * 1000;
    for (i = 0; i < 32; i += 7) mix(flat[i]);

    for (i = 0; i < 16; i++) bytes[i] = (char)(i * 3);
    for (i = 0; i < 16; i += 3) mix(bytes[i]);

    {
        int *q = local;
        mix(*q); mix(*(q + 3)); mix(q[5]);
        q += 2;
        mix(*q);
        q++;
        mix(*q);
        mix((int)(q - local));
    }
    {
        char *c = bytes;
        mix(*c);
        c += 5;
        mix(*c);
        mix((int)(c - bytes));
    }
    return checksum & 0xff;
}
