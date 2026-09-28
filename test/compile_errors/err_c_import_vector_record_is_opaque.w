//! expect-error: cannot create value of opaque type

// §16.1: a record holding a C vector type is opaque; a program cannot
// build one by value.
use c_import("typedef int v4si __attribute__((__vector_size__(16)));
typedef struct holder { int tag; v4si lanes; } holder;
v4si vadd(v4si a, v4si b);
")

fn main:
    let h = holder { tag: 1 }
    print(f"{h.tag}")
