//! expect-check-fail: is already part of a buffer pairing; a parameter is paired once

// D64 §16.2b.8: a parameter appears in one pairing only.
use c_import("static inline int cmp(const unsigned char *a, const unsigned char *b, unsigned long n) { return a[0] - b[0] + (int)n; }\n")

c facade cmps:
    fn cmp
        buffer param a len param n
        buffer param b len param n

fn main:
    print("unreachable")
