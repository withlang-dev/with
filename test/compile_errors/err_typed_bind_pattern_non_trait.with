//! expect-error: only valid to downcast a trait object

// #663: `x: Type` in a pattern is a dynamic trait-object downcast. On a
// concrete variant payload (i32) it has no meaning and used to register a
// garbage resolver binding, then crash in the dyn-vtable lowering. Reject it.
use std.builtins.print_i32
enum E:
    V(i32)

fn main:
    let e = E.V(5)
    match e:
        V(x: i32) => print_i32(x)
        _ => print_i32(0)
