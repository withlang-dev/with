//! expect-error: unknown type

// §16.2: with `only`, non-requested symbols are not imported.

use c_import("typedef struct { int x; } Point;\ntypedef struct { int y; } Other;\n", only: ["Point"])

fn main:
    let o = Other { y: 1 }
    print("x")
