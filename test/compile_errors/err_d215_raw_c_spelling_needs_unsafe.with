//! expect-check-fail: `c.f` is the raw C function and requires unsafe context (§31)

// D215: the raw spelling always needs `unsafe`.
use c_import("static inline int f(int x) { return x; }")
fn main:
    print(c.f(1))
