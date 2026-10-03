//! expect-stdout: 2

// #1882 (§18.2, D70): a function a c_import header defines is its
// importer's import, not a global declaration. lib/std/re/defs.w reaches
// every compilation over the prelude edge and has a private
// `u128_mul_would_overflow(a: u128, b: u128)`; a header defining a
// one-parameter function of that name used to capture the bundle's own
// calls ("function 'u128_mul_would_overflow' expects 1 argument(s), found
// 2" at lib/std/re/defs.w). The importer's call binds to the header's
// function; the bundle's bind to its own.
use c_import("static inline int u128_mul_would_overflow(int a) { return a + 1; }\n")

fn main:
    print(u128_mul_would_overflow(1))
