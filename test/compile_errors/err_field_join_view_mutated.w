//! expect-check-fail: while `p` is a live view into it

// #1408 (§3.8 join rule 3, §21.1): a join of field places is a view carrying
// the union of the arms' origins, so the owner cannot change while it lives —
// the element join's rule (#1406).
use std.process

type S { s: str }

fn main:
    var x = S { s: "x" ++ "y" }
    let y = S { s: "u" ++ "v" }
    let p = if args().len() > 0: x.s else: y.s
    x.s = "z".clone()
    print(p)
