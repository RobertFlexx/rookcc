/* Structs, unions, bit-fields, nested aggregates and by-value passing. */
#include <stdio.h>
#include <string.h>

struct point { int x, y; };

struct rect {
    struct point lo, hi;
    char tag[8];
};

struct packed {
    unsigned int a : 3;
    unsigned int b : 5;
    unsigned int c : 1;
    int d : 7;
};

union bits {
    unsigned long whole;
    unsigned char byte[8];
};

static struct rect boxes[2] = {
    {{0, 0}, {4, 5}, "first"},
    {{-2, -3}, {2, 3}, "second"}
};

/* Designated initializers, at file scope and nested. */
static struct rect designated = {.hi = {.y = 9}, .tag = "des"};

static int area(struct rect r) {
    return (r.hi.x - r.lo.x) * (r.hi.y - r.lo.y);
}

static struct point offset(struct point p, int dx, int dy) {
    struct point q;
    q.x = p.x + dx;
    q.y = p.y + dy;
    return q;
}

int main(void) {
    struct rect local = {{1, 1}, {3, 7}, "loc"};
    struct packed bits;
    union bits u;
    struct point p;
    int i;

    printf("sz %d %d %d\n", (int)sizeof(struct point),
           (int)sizeof(struct rect), (int)sizeof(union bits));
    for (i = 0; i < 2; i++)
        printf("box%d %d %d %d %d %s %d\n", i, boxes[i].lo.x, boxes[i].lo.y,
               boxes[i].hi.x, boxes[i].hi.y, boxes[i].tag, area(boxes[i]));
    printf("loc %d %s\n", area(local), local.tag);

    p = offset(local.lo, 10, 20);
    printf("off %d %d\n", p.x, p.y);

    bits.a = 5; bits.b = 21; bits.c = 1; bits.d = -20;
    printf("bf %u %u %u %d\n", bits.a, bits.b, bits.c, bits.d);
    bits.a = bits.a + 2;
    bits.d = bits.d + 5;
    printf("bf2 %u %d\n", bits.a, bits.d);

    u.whole = 0;
    u.byte[0] = 0xAA;
    u.byte[7] = 0x11;
    printf("un %lu %u %u\n", u.whole, u.byte[0], u.byte[7]);

    {
        struct rect copy = local;
        copy.hi.x = 99;
        printf("cp %d %d %s\n", local.hi.x, copy.hi.x, copy.tag);
    }
    {
        struct point arr[3];
        long acc = 0;
        for (i = 0; i < 3; i++) { arr[i].x = i; arr[i].y = i * i; }
        for (i = 0; i < 3; i++) acc += arr[i].x * 10 + arr[i].y;
        printf("arr %ld\n", acc);
    }
    {
        struct point *ptr = &local.lo;
        ptr->x = 42;
        printf("ptr %d %d\n", local.lo.x, ptr->y);
    }
    {
        struct rect inner = {.lo = {3, 4}, .tag = "in"};
        printf("des %d %d %d %s | %d %d %s\n", designated.lo.x,
               designated.hi.y, designated.hi.x, designated.tag,
               inner.lo.x, inner.hi.y, inner.tag);
    }
    return 0;
}
