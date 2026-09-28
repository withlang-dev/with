//! expect-error: c_import symbol 'vadd' was omitted

// §16.1: a function taking a C vector type is omitted (With has no SIMD
// vector type and an array spelling would lie about its ABI); calling it
// names the omission rather than compiling to a wrong call.
use c_import("typedef int v4si __attribute__((__vector_size__(16)));
typedef struct holder { int tag; v4si lanes; } holder;
v4si vadd(v4si a, v4si b);
")

fn main:
    let r = vadd(1, 2)
    print("x")
