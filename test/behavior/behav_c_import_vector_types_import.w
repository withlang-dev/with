//! expect-stdout: 7 3 16 32
// §16.1 (D78, #1874; retires #1872's omission): a C vector typedef imports
// as `Vector[N, T]` (here the alias `i32x4`), a record holding one keeps
// its fields and C's layout, and the rest of the header imports with it.
// MSVC's <intrin.h> (reached from SDL3 on Windows) declares vector
// typedefs such as AMX's `_tile1024i`.
use c_import("typedef int v4si __attribute__((__vector_size__(16)));\ntypedef struct holder { int tag; v4si lanes; } holder;\nv4si vadd(v4si a, v4si b);\nstatic inline int plain(int x) { return x + 1; }\n")

fn main:
    let h = holder { tag: 1, lanes: i32x4(0, 1, 2, 3) }
    let lanes: v4si = h.lanes
    print(f"{plain(6)} {lanes[3]} {size_of[v4si]()} {size_of[holder]()}")
