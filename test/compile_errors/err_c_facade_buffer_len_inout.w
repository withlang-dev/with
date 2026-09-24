//! expect-check-fail: pairs an input buffer, which C only reads

// D64 §16.2b.8: `len` is an input pairing; `inout` belongs to `capacity`.
use c_import("static inline int sum_bytes(const unsigned char *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n inout

fn main:
    print("unreachable")
