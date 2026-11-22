//! expect-check-fail: cannot be stored on the heap

// #600 (§5.1): Rc.new / Arc.new are heap-owning constructors — same rejection
// as Box.new for ephemeral values.

use std.rc

type StrView ephemeral { s: &str }

fn main:
    let owned = "hello"
    let view = StrView { s: owned }
    let shared = Rc.new(view)
    print("no")
