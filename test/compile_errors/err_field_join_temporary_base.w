//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1408 (§3.8 join rule 4): "An owned temporary is never implicitly borrowed
// merely to force a reference result." A field of a call's result is no
// place, so the join stays owned and the arm is an implicit field move.
use std.process

type S { s: str }

fn mk() -> S: S { s: "t" ++ "m" }

fn main:
    let y = S { s: "u" ++ "v" }
    let p = if args().len() > 0: mk().s else: y.s
    print(p)
