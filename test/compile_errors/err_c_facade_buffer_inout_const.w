//! expect-check-fail: a const pointer; C cannot write into it

// D64 §16.2b.8: a buffer C fills is not const.
use c_import("static inline int fill(const unsigned char *dst, unsigned long *dstLen) { *dstLen = 0; return dst[0]; }\n")

c facade fills:
    fn fill
        buffer param dst capacity param dstLen inout

fn main:
    print("unreachable")
