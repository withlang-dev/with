//! expect-check-fail: a field never moves out implicitly

// #782 → D32 (§2.2): the assignment-RHS bare field read that used to move
// implicitly (and made the later whole use an error) now errors at the
// move site itself — the site-local rule subsumes the flow-conditional one.
// A Vec field, not a str: a str field read copies (D111).

use std.builtins.print_i64
type Capability { root: Vec[i32], name: str }

fn takes_whole(c: &Capability) -> i64: c.root.len()

fn main:
    let cap = Capability { root: [1, 2], name: "ws" }
    var picked: Vec[i32] = Vec.new()
    picked = cap.root
    let n = takes_whole(cap)
    print_i64(n)
    print(picked.len())
