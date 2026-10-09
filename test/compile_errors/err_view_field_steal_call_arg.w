//! expect-error: cannot take ownership of a non-Copy field through a borrow

// D22 §13.6 / #735: a by-value parameter is an owned demand and cannot be
// satisfied from a non-Copy field reached through a shared view.

use std.builtins.int_to_string
type Outer { v: List[i32], n: i32 }

fn takes_owned(x: List[i32]) -> i64:
    x.len()

fn main:
    var o = Outer { v: List.new(), n: 7 }
    o.v.push(1)
    let r = &o
    print(int_to_string(takes_owned(r.v)))
