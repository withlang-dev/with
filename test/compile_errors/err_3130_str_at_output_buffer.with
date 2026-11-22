//! expect-check-fail: argument expression 'text' has type str

// #3130 (§16.2b.8): a `str` is accepted at an input buffer only. `capacity
// … inout` is storage C writes, and a `str` is never written through.
use c_import("#define FILL_OK 0\nstatic inline int fill(unsigned char *dst, unsigned long *dstLen) { dst[0] = 1; *dstLen = 1; return FILL_OK; }\n")

c contract fills:
    fn fill
        buffer param dst capacity param dstLen inout
        ok FILL_OK

fn main:
    var text = "abc"
    let n = fill(text).unwrap()
    print(n)
