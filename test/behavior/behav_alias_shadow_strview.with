//! expect-stdout: 7
// §4.1 (#627, decisions.md D3): a user `type StrView` shadows the prelude
// alias — the visible user declaration wins.
use std.builtins.print_i32
type StrView { tag: i32 }
fn main:
    let v = StrView { tag: 7 }
    print_i32(v.tag)
