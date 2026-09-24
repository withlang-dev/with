//! expect-check-fail: one operation has one result

// D64 §16.2b.8: an inout capacity is presented as the result; a `returns`
// clause presents the return. Both cannot be the one result.
use c_import("static inline const char *name_into(char *dst, unsigned long *dstLen) { *dstLen = 0; return \"x\"; }\n")

c facade names:
    fn name_into
        buffer param dst capacity param dstLen inout
        returns static CStr

fn main:
    print("unreachable")
