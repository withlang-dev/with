//! expect-stdout: 10
//! expect-stdout: 11

// #1882: a module that defines a function and imports a header defining
// one of the same name calls its own (§18.2 tier 2: the module's own
// declaration), and the header's through its namespace (D70).
use c_import("static inline int twice(int a) { return a * 2 + 1; }\n") as hdr

fn twice(a: i32) -> i32: a * 2

fn main:
    print(twice(5))
    print(hdr.twice(5))
