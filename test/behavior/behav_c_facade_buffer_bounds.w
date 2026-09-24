//! expect-exit: 134
//! expect-stderr: C reported 64 bytes written into a buffer of 8 bytes

// D64 (spec §16.2b.8): the length C writes back is bounds-checked against
// the capacity before it becomes a With value. A C function that reports
// more bytes than the buffer holds has broken its contract; the presented
// call fails loudly, naming the operation and the reported length — it is
// never trusted into a `usize` that a caller would slice with.

use c_import("#define LIE_OK 0\nstatic inline int lie(unsigned char *dst, unsigned long *dstLen) { dst[0] = 1; *dstLen = 64; return LIE_OK; }\n")

c facade lies:
    fn lie
        buffer param dst capacity param dstLen inout
        ok LIE_OK

fn main:
    var dest: [u8; 8] = [0 as u8; 8]
    let n = lie(dest).unwrap()
    print(f"unreachable: {n}")
