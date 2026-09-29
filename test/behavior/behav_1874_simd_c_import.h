#ifndef BEHAV_1874_SIMD_C_IMPORT_H
#define BEHAV_1874_SIMD_C_IMPORT_H

// §16.1 (D78, #1874): C vector types import as Vector[N, T] and print as
// the alias for the native widths.
typedef float with_v4f __attribute__((vector_size(16)));
typedef long long with_v2ll __attribute__((vector_size(16)));
typedef float with_v8f __attribute__((vector_size(32)));
typedef float with_v3f __attribute__((ext_vector_type(3)));
typedef unsigned char with_v16u8 __attribute__((vector_size(16)));

typedef struct {
    with_v3f position;
    float weight;
} with_vertex;

// A vector over 16 bytes: 32-aligned on x86_64, 16-aligned on AArch64.
typedef struct {
    int tag;
    with_v8f wide;
    int tail;
} with_wide;

enum {
    WITH_VERTEX_SIZE = sizeof(with_vertex),
    WITH_VERTEX_ALIGN = _Alignof(with_vertex),
    WITH_V3F_SIZE = sizeof(with_v3f),
    WITH_V8F_ALIGN = _Alignof(with_v8f),
    WITH_WIDE_SIZE = sizeof(with_wide),
    WITH_WIDE_ALIGN = _Alignof(with_wide),
    WITH_WIDE_TAIL = __builtin_offsetof(with_wide, tail),
};

static inline with_v4f with_v4f_scale(with_v4f v, float k) { return v * k; }
static inline with_v3f with_v3f_add(with_v3f a, with_v3f b) { return a + b; }
static inline long long with_v2ll_sum(with_v2ll v) { return v[0] + v[1]; }
static inline float with_wide_lane(with_wide w) { return w.wide[5] + (float)w.tail; }

#endif
