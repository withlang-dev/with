// Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once.
// Timed region: everything. Checksum: wrapping sum of the words written.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define ITERATIONS 2000000
#define RING 32

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1000000.0;
}

int main(void) {
    double start = now_ms();
    uint64_t *ring[RING] = {0};
    uint64_t checksum = 0;
    for (size_t i = 0; i < ITERATIONS; i++) {
        size_t words = 1024 * (1 + (i % 8));
        uint64_t *block = malloc(words * sizeof(uint64_t));
        for (size_t j = 0; j < words / 64; j++) {
            uint64_t value = (uint64_t)i * 2654435761ULL + (uint64_t)j;
            block[j] = value;
            checksum += value;
        }
        free(ring[i % RING]);
        ring[i % RING] = block;
    }
    for (int s = 0; s < RING; s++) free(ring[s]);
    double elapsed_ms = now_ms() - start;
    printf("iterations %d ring %d\n", ITERATIONS, RING);
    printf("elapsed_ms %.3f\n", elapsed_ms);
    printf("checksum %llu\n", (unsigned long long)checksum);
    return 0;
}
