//! expect-check-fail: which is not a pointer to an integer; C reads the capacity through it
//! expect-check-fail: = help: when the count is passed by value, write 'len param 1'

// D64 §16.2b.8: an inout capacity is written back through a pointer.
use c_import("static inline int fill(unsigned char *dst, unsigned long dstLen) { dst[0] = 1; return 0; }\n")

c contract fills:
    fn fill
        buffer param dst capacity param dstLen inout

fn main:
    print("unreachable")
