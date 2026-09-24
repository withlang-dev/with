//! expect-check-fail: is part of a buffer pairing and cannot also be fixed

// D64 §16.2b.8, §16.2b.11: a fixed parameter is not a buffer or its length.
use c_import("static inline int sum_bytes(const unsigned char *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param n
        param n fixed 4

fn main:
    print("unreachable")
