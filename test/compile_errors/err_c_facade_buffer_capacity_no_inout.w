//! expect-check-fail: a capacity is read on entry and written back

// D64 §16.2b.8: the ruling pairs a capacity C reads and writes back; an
// output-only length is not ruled, so `capacity` without `inout` is a
// parse error, not a silent input pairing.
use c_import("static inline int fill(unsigned char *dst, unsigned long *dstLen) { *dstLen = 0; return 0; }\n")

c facade fills:
    fn fill
        buffer param dst capacity param dstLen

fn main:
    print("unreachable")
