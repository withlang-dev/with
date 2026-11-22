//! expect-stdout: ok

// #379 buf_out: memset models its (void*, size_t) pair as a single `[]mut u8`.
// A plain array argument coerces at the call site (#604 stage 1); the slice
// length bounds the C write; no unsafe in user code. (explicit_bzero is
// curated too but absent from Darwin libc, so the fixture exercises memset.)

use c_import("void *memset(void *s, int c, unsigned long n);\n")

fn zero(buf: []mut u8):
    memset(buf, 0)

fn main:
    var a = [1u8, 2u8, 3u8]
    memset(a, 9)
    if a[0] != 9u8 or a[1] != 9u8 or a[2] != 9u8:
        print("bad-memset")
        return
    zero(a)
    if a[0] != 0u8 or a[1] != 0u8 or a[2] != 0u8:
        print("bad-zero")
        return
    print("ok")
