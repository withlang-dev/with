//! expect-check-fail: a field never moves out implicitly

// #782 → D32 (§2.2): the assignment-RHS bare field read that used to move
// implicitly (and made the later whole use an error) now errors at the
// move site itself — the site-local rule subsumes the flow-conditional one.
// A List field, not a str: a str field read copies (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.builtins.print_i64
type Capability { root: List[Tok], name: str }

fn takes_whole(c: &Capability) -> i64: c.root.len()

fn main:
    let cap = Capability { root: [Tok { id: 1 }, Tok { id: 2 }], name: "ws" }
    var picked: List[Tok] = List.new()
    picked = cap.root
    let n = takes_whole(cap)
    print_i64(n)
    print(picked.len())
