//! expect-stdout: ok

// #379 buf_in: memcmp's two (const void*, size_t) buffers share one length. The
// wrapper takes two `[]u8` and requires equal lengths (panics otherwise).

use c_import("int memcmp(const void *a, const void *b, unsigned long n);\n")

fn main:
    let x = [1u8, 2u8, 3u8]
    let y = [1u8, 2u8, 3u8]
    let z = [1u8, 2u8, 4u8]
    if memcmp(x[0..3], y[0..3]) == 0 and memcmp(x[0..3], z[0..3]) != 0:
        print("ok")
    else:
        print("bad")
