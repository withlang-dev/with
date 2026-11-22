//! expect-check-fail: use of moved value

// #1380 (§2.2): a value `if` whose arm is a whole binding yields that
// binding by value — MIR moves it into the join (reset-on-move blanks the
// source) exactly as `let p = a` does. The second read used to compile and
// read an empty value silently. A List, not a str: a str is a value and is
// copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.process

fn main:
    let a: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    let b: List[Tok] = [Tok { id: 3 }]
    let c = args().len() > 0
    let p = if c: a else: b
    let q = if c: a else: b
    print(f"[{p.len()}] [{q.len()}]")
