/* Fixed-point n-body integration: dense array indexing and arithmetic. */
#include <stdio.h>

#define N 96
#define STEPS 900

static long px[N], py[N], vx[N], vy[N], mass[N];

int main(void) {
    int i, j, s;
    for (i = 0; i < N; i++) {
        px[i] = (i * 7919) % 1000 - 500;
        py[i] = (i * 6271) % 1000 - 500;
        vx[i] = 0;
        vy[i] = 0;
        mass[i] = (i % 7) + 1;
    }
    for (s = 0; s < STEPS; s++) {
        for (i = 0; i < N; i++) {
            long ax = 0, ay = 0;
            for (j = 0; j < N; j++) {
                long dx, dy, d2, inv;
                if (i == j) continue;
                dx = px[j] - px[i];
                dy = py[j] - py[i];
                d2 = dx * dx + dy * dy;
                if (d2 < 16) d2 = 16;
                inv = (mass[j] * 4096) / d2;
                ax += (dx * inv) / 256;
                ay += (dy * inv) / 256;
            }
            vx[i] += ax / 64;
            vy[i] += ay / 64;
        }
        for (i = 0; i < N; i++) {
            px[i] += vx[i] / 32;
            py[i] += vy[i] / 32;
        }
    }
    {
        long checksum = 0;
        for (i = 0; i < N; i++)
            checksum += px[i] * 3 + py[i] * 5 + vx[i] * 7 + vy[i] * 11;
        printf("nbody %ld\n", checksum);
    }
    return 0;
}
