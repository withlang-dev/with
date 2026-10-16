//! expect-error: cannot take ownership of a non-Copy field through a borrow

// D22 §13.6 / #735: a struct-literal field is an owned demand and cannot be
// filled from a non-Copy field reached through a shared view.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.builtins.int_to_string
type Outer { v: List[Tok], n: i32 }
type Wrap { held: List[Tok] }

fn main:
    var o = Outer { v: List.new(), n: 7 }
    o.v.push(Tok { id: 1 })
    let r = &o
    let w = Wrap { held: r.v }
    print(int_to_string(w.held.len()))
