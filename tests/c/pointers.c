/* Pointer arithmetic, function pointers, strings and memory routines. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int add(int a, int b) { return a + b; }
static int sub(int a, int b) { return a - b; }
static int mul(int a, int b) { return a * b; }

typedef int (*binop)(int, int);

static int apply_all(const int *values, int count, binop op, int seed) {
    int i, acc = seed;
    for (i = 0; i < count; i++) acc = op(acc, values[i]);
    return acc;
}

int main(void) {
    int data[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    int *p = data;
    int *q = data + 5;
    binop ops[3];
    char buffer[32];
    char *heap;
    int i;

    printf("pa %d %d %d %ld\n", *p, *q, *(q - 2), (long)(q - p));
    p += 3;
    printf("pb %d", *p);
    printf(" %d\n", *--p);
    p++;
    printf("pc %d", *p++);
    printf(" %d\n", *p);
    printf("pd %d %d %d\n", p[-1], p[0], p[1]);
    printf("pe %d %d\n", (int)(p > data), (int)(p == data + 4));

    ops[0] = add; ops[1] = sub; ops[2] = mul;
    for (i = 0; i < 3; i++)
        printf("op%d %d\n", i, apply_all(data, 4, ops[i], i == 2 ? 1 : 0));

    strcpy(buffer, "hello");
    strcat(buffer, ", world");
    printf("st %s %d %d\n", buffer, (int)strlen(buffer),
           strcmp(buffer, "hello, world"));
    memset(buffer, 'x', 5);
    buffer[5] = 0;
    printf("ms %s\n", buffer);

    heap = (char *)malloc(64);
    if (heap == NULL) { printf("alloc failed\n"); return 1; }
    for (i = 0; i < 63; i++) heap[i] = (char)('a' + (i % 26));
    heap[63] = 0;
    printf("hp %d %c %c\n", (int)strlen(heap), heap[0], heap[62]);
    memmove(heap + 1, heap, 10);
    heap[12] = 0;
    printf("mm %s\n", heap);
    free(heap);

    {
        const char *words[4] = {"alpha", "beta", "gamma", "delta"};
        unsigned long h = 5381;
        const char *s;
        for (i = 0; i < 4; i++)
            for (s = words[i]; *s; s++) h = h * 33u + (unsigned char)*s;
        printf("hs %lu\n", h);
    }
    {
        void *v = data;
        int *back = (int *)v;
        printf("cv %d %d\n", back[0], back[7]);
    }
    return 0;
}
