// Words: string building, hashing, and map lookup over 30M generated words.
// Timed region: everything. Checksum: order-independent FNV mix of the counts
// folded with an FNV of a 1000-line report built from lookups.
// The map is a hand-written open-addressing table, as C programs carry.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define WORDS 30000000
#define VOCAB 60000ULL
#define HOT 600ULL
#define CAP (1u << 18)

typedef struct { char *key; int32_t count; } Entry;
static Entry table[CAP];
static size_t distinct = 0;

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

static uint64_t next(uint64_t x) { x ^= x << 13; x ^= x >> 7; x ^= x << 17; return x; }

static size_t spell(uint64_t id, char *out) {
    uint64_t v = id + 676;
    size_t n = 0;
    while (v > 0) { out[n++] = (char)('a' + v % 26); v /= 26; }
    out[n] = 0;
    return n;
}

static uint64_t fnv(const char *s, size_t n) {
    uint64_t h = 14695981039346656037ULL;
    for (size_t i = 0; i < n; i++) h = (h ^ (uint8_t)s[i]) * 1099511628211ULL;
    return h;
}

static Entry *lookup(const char *key, size_t n) {
    size_t i = fnv(key, n) & (CAP - 1);
    while (table[i].key) {
        if (strcmp(table[i].key, key) == 0) return &table[i];
        i = (i + 1) & (CAP - 1);
    }
    return &table[i];
}

int main(void) {
    double start = now_ms();
    uint64_t rng = 88172645463325252ULL;
    char word[32];
    for (int i = 0; i < WORDS; i++) {
        rng = next(rng);
        uint64_t id = (rng % 10 < 3) ? (rng >> 8) % HOT : (rng >> 8) % VOCAB;
        size_t n = spell(id, word);
        Entry *e = lookup(word, n);
        if (!e->key) { e->key = strdup(word); distinct++; }
        e->count += 1;
    }
    uint64_t mix = 0;
    for (size_t i = 0; i < CAP; i++)
        if (table[i].key) mix += (uint64_t)table[i].count * fnv(table[i].key, strlen(table[i].key));
    size_t cap = 1 << 16, len = 0;
    char *report = malloc(cap);
    for (uint64_t id = 0; id < 1000; id++) {
        size_t n = spell(id, word);
        Entry *e = lookup(word, n);
        int32_t count = e->key ? e->count : 0;
        if (len + 64 > cap) { cap *= 2; report = realloc(report, cap); }
        len += (size_t)sprintf(report + len, "%s:%d\n", word, count);
    }
    uint64_t checksum = mix ^ fnv(report, len);
    double elapsed_ms = now_ms() - start;
    printf("distinct %zu report_bytes %zu\n", distinct, len);
    printf("elapsed_ms %.3f\n", elapsed_ms);
    printf("checksum %llu\n", (unsigned long long)checksum);
    return 0;
}
