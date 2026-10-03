//! expect-stdout: 42 -1 1 0

// #1882 retires #1877's workaround: an import's overflow helpers now carry
// the migrator's spelling (`__with_builtin_mul_overflow_<ty>`, the shared
// `u128_mul_would_overflow`), the names lib/std/re/defs.w defines for
// itself over the prelude edge. Each owner's definitions are its own: the
// header's inline bodies call the import's helpers, the bundle's code its
// own — including the 128-bit multiply's shared limb check.
use c_import("static inline long long mul_or_neg(unsigned int a, unsigned int b) { unsigned int r; if (__builtin_mul_overflow(a, b, &r)) return -1; return (long long)r; }\nstatic inline int wide_mul_ok(unsigned __int128 a, unsigned __int128 b) { unsigned __int128 r; return __builtin_mul_overflow(a, b, &r) ? 0 : 1; }\n")

fn main:
    let a = mul_or_neg(6, 7)
    let b = mul_or_neg(65536, 65536)
    let c = wide_mul_ok(6u128, 7u128)
    let d = wide_mul_ok(1u128 << 100, 1u128 << 100)
    print(f"{a} {b} {c} {d}")
