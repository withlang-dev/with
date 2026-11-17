//! expect-check-fail: with no status contract
//! expect-check-fail: = help: state the success status: 'ok <CONST>' (§16.2b.4)

// D64 §16.2b.8: the copied-back length is presented only on success, which
// a status-returning operation states with `ok`.
use c_import("static inline int fill(unsigned char *dst, unsigned long *dstLen) { dst[0] = 1; *dstLen = 1; return 0; }\n")

c contract fills:
    fn fill
        buffer param dst capacity param dstLen inout

fn main:
    print("unreachable")
