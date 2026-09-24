//! expect-check-fail: with itself; a pairing names the pointer and the distinct integer

// D64 §16.2b.8: both parameters of a pairing exist and are distinct.
use c_import("static inline int sum_bytes(const unsigned char *p, unsigned long n) { if (n > 0) return p[0]; return 0; }\n")

c facade sums:
    fn sum_bytes
        buffer param p len param p

fn main:
    print("unreachable")
