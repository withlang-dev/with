//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1408: a join of field places is a view only when nothing establishes an
// owned result. A typed binding demands what it says (D22 §6.2, D27), so each
// arm is an implicit field move (§2.2, D32; §3.8 join rules 2 and 5).
use std.process

type S { s: str }

fn main:
    let x = S { s: "x" ++ "y" }
    let y = S { s: "u" ++ "v" }
    let p: str = if args().len() > 0: x.s else: y.s
    print(p)
