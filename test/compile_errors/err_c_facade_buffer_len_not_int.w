//! expect-check-fail: which is not an integer; the length parameter carries the byte count

// D64 §16.2b.8: the length parameter is the integer C reads.
use c_import("static inline int scan(const unsigned char *p, const char *n) { return p[0] + n[0]; }\n")

c facade scans:
    fn scan
        buffer param p len param n

fn main:
    print("unreachable")
