//! expect-stdout: 7
// §16.1: With has no SIMD vector type, so c_import omits a vector typedef,
// makes a record holding a vector opaque, and omits a function taking one;
// the rest of the header still imports. MSVC's <intrin.h> (reached from
// SDL3 on Windows) declares vector typedefs such as AMX's `_tile1024i`,
// whose `Vector(...)` spelling used to break the whole import.
use c_import("typedef int v4si __attribute__((__vector_size__(16)));\ntypedef struct holder { int tag; v4si lanes; } holder;\nv4si vadd(v4si a, v4si b);\nstatic inline int plain(int x) { return x + 1; }\n")

fn main:
    print(f"{plain(6)}")
