//! expect-check-fail: a const pointer; C cannot write into it
//! expect-check-fail: = help: an input buffer is 'buffer param 0 len param N', with N the integer parameter that carries its length

// D64 §16.2b.8: a buffer C fills is not const.
use c_import("static inline int fill(const unsigned char *dst, unsigned long *dstLen) { *dstLen = 0; return dst[0]; }\n")

c contract fills:
    fn fill
        buffer param dst capacity param dstLen inout

fn main:
    print("unreachable")
