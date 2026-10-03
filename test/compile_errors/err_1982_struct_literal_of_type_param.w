//! expect-error: struct literal of `T`, which is `i32` in this instantiation and not a struct

// #1982: a struct literal needs a struct type. `mk(3)` instantiates `T` as
// `i32`; the literal was left untyped and MIR projected a field of a
// scalar (invalid MIR after Sema).
fn mk[T](x: T) -> T: T { v: 1 }

fn main:
    print(mk(3))
