//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1408: a join of field places is a view only when nothing establishes an
// owned result. A typed binding demands what it says (D22 §6.2, D27), so each
// arm is an implicit field move (§2.2, D32; §3.8 join rules 2 and 5).
// A List field, not a str: a str field read copies (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.process

type S { s: List[Tok] }

fn main:
    let x = S { s: [Tok { id: 1 }] }
    let y = S { s: [Tok { id: 2 }] }
    let p: List[Tok] = if args().len() > 0: x.s else: y.s
    print(p.len())
