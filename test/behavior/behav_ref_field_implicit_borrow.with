//! expect-stdout: 5

// #747: a &-typed struct field initialized from a place is an implicit
// borrow — MIR must store the place ADDRESS, not bit-copy the value into
// the ref slot (a str header read as a pointer was the derive_deserialize
// SEGV).
use std.builtins.print_i32
type RefFieldOwner { s: str }
type RefFieldView ephemeral: Copy { r: &str }
fn mk(o: &RefFieldOwner) -> RefFieldView: RefFieldView { r: o.s }
fn main:
    let o = RefFieldOwner { s: "hello" }
    let v = mk(&o)
    print_i32(v.r.len() as i32)
