//! expect-stdout: 5

// §16.2: selective c_import — `only` keeps just the requested symbols.

use c_import("typedef struct { int x; } Point;\ntypedef struct { int y; } Other;\n", only: ["Point"])

fn main:
    let p = Point { x: 5 }
    print(f"{p.x}")
