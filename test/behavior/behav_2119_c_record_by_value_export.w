//! expect-stdout: 42
// #2119, §16.1: a C record is `@[repr(C)]`, so an exported function may take
// one by value.
use c_import("struct Pair { int a; int b; };\n")

@[c_export("pair_sum")]
fn pair_sum(p: Pair) -> c_int: p.a + p.b

fn main: print(pair_sum(Pair { a: 20, b: 22 }))
