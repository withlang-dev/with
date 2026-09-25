// Grow: push-built vectors inside a struct, 800 rounds of 100k rows each.
// Timed region: everything. Checksum: wrapping fold over the rows.
// The vector is the doubling array every C program carries.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define ROUNDS 800
#define ROWS 100000

typedef struct { int64_t *data; size_t len, cap; } Vec;
typedef struct { Vec xs, ys, ids; } Table;

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

static uint64_t next(uint64_t x) { x ^= x << 13; x ^= x >> 7; x ^= x << 17; return x; }

static void push(Vec *v, int64_t value) {
    if (v->len == v->cap) {
        v->cap = v->cap ? v->cap * 2 : 4;
        v->data = realloc(v->data, v->cap * sizeof(int64_t));
    }
    v->data[v->len++] = value;
}

static void push_row(Table *t, uint64_t r, int64_t id) {
    push(&t->xs, (int64_t)(r % 1000));
    push(&t->ys, (int64_t)((r >> 10) % 1000));
    push(&t->ids, id);
}

static int64_t fold(const Table *t) {
    uint64_t total = 0;
    for (size_t i = 0; i < t->ids.len; i++)
        total += (uint64_t)(t->xs.data[i] * 3 + t->ys.data[i] * 7 + t->ids.data[i]);
    return (int64_t)total;
}

int main(void) {
    double start = now_ms();
    uint64_t rng = 2463534242ULL;
    uint64_t checksum = 0;
    for (int64_t round = 0; round < ROUNDS; round++) {
        Table t = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}};
        for (int64_t i = 0; i < ROWS; i++) {
            rng = next(rng);
            push_row(&t, rng, round * ROWS + i);
        }
        checksum += (uint64_t)fold(&t);
        free(t.xs.data); free(t.ys.data); free(t.ids.data);
    }
    double elapsed_ms = now_ms() - start;
    printf("rounds %d rows %d\n", ROUNDS, ROWS);
    printf("elapsed_ms %.3f\n", elapsed_ms);
    printf("checksum %lld\n", (long long)(int64_t)checksum);
    return 0;
}
