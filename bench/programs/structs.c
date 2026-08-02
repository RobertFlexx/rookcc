/* Struct field access, pointer chasing and a linked free list. */
#include <stdio.h>

#define COUNT 3000
#define ROUNDS 2600

struct particle {
    long x, y;
    long vx, vy;
    int kind;
    int alive;
    struct particle *next;
};

static struct particle nodes[COUNT];

static long advance(struct particle *p) {
    p->x += p->vx;
    p->y += p->vy;
    if (p->x > 10000 || p->x < -10000) p->vx = -p->vx;
    if (p->y > 10000 || p->y < -10000) p->vy = -p->vy;
    return p->x + p->y;
}

int main(void) {
    int i, r;
    long acc = 0;
    struct particle *head = 0;
    for (i = 0; i < COUNT; i++) {
        nodes[i].x = (i * 31) % 997;
        nodes[i].y = (i * 17) % 991;
        nodes[i].vx = (i % 11) - 5;
        nodes[i].vy = (i % 7) - 3;
        nodes[i].kind = i % 4;
        nodes[i].alive = 1;
        nodes[i].next = head;
        head = &nodes[i];
    }
    for (r = 0; r < ROUNDS; r++) {
        struct particle *p = head;
        while (p) {
            if (p->alive) acc += advance(p);
            if (p->kind == 3 && (acc & 1023) == 0) p->alive = !p->alive;
            p = p->next;
        }
    }
    printf("structs %ld\n", acc);
    return 0;
}
