/* Freestanding: structs, unions, nested aggregates, arrays of structs. */

static int checksum;

static void mix(long v) { checksum = (int)((checksum * 31 + v) & 0x7fffffff); }

struct point { int x, y; };

struct body {
    struct point pos;
    struct point vel;
    long mass;
    int kind;
};

union view {
    long whole;
    int halves[2];
};

static struct body bodies[4];
static struct point origin = {3, 4};

static int manhattan(struct point p) { return (p.x < 0 ? -p.x : p.x) + (p.y < 0 ? -p.y : p.y); }

static struct point advance(struct point p, struct point v) {
    struct point r;
    r.x = p.x + v.x;
    r.y = p.y + v.y;
    return r;
}

int main(void) {
    int i;
    struct body local;
    union view u;

    for (i = 0; i < 4; i++) {
        bodies[i].pos.x = i;
        bodies[i].pos.y = i * 2;
        bodies[i].vel.x = -i;
        bodies[i].vel.y = i + 1;
        bodies[i].mass = (long)i * 100;
        bodies[i].kind = i % 3;
    }
    for (i = 0; i < 4; i++) {
        mix(bodies[i].pos.x); mix(bodies[i].pos.y);
        mix(bodies[i].mass); mix(bodies[i].kind);
    }

    local = bodies[2];
    local.pos.x = 99;
    mix(local.pos.x);
    mix(bodies[2].pos.x);
    mix(local.pos.y);

    {
        struct body *b = &bodies[1];
        b->pos.x += 10;
        b->mass *= 2;
        mix(b->pos.x); mix(bodies[1].pos.x); mix(b->mass);
        mix(b->vel.y);
    }

    mix(origin.x); mix(origin.y);
    mix(manhattan(origin));
    {
        struct point moved = advance(origin, bodies[3].vel);
        mix(moved.x); mix(moved.y);
    }

    u.whole = 0;
    u.halves[0] = 0x11223344;
    mix(u.halves[0]);
    mix((int)(u.whole & 0xffff));

    mix((int)sizeof(struct point));
    mix((int)sizeof(struct body));
    mix((int)sizeof(bodies));
    return checksum & 0xff;
}
