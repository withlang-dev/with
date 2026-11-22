//! expect-check-fail: takes `U` by value, and field 'p'
// D198 (§16.2b.5): a pointer in a union member is the same pointer, written here through the integer member.
use c_import("typedef union { const int *p; long n; } U; static inline int u_first(U u) { return *u.p; }")

fn main:
    let u = U { n: 4096 }
    print(f"{u_first(u)}")
