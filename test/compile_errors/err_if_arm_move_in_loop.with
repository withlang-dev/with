//! expect-check-fail: is moved inside a loop

// #1380 (§2.2): an `if` arm that yields an outer binding moves it on every
// iteration, the same as the unconditional `let p = a` in a loop. A List,
// not a str: a str is a value and is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    let a: List[Tok] = [Tok { id: 1 }]
    let b: List[Tok] = [Tok { id: 2 }]
    for k in 0..2:
        let p = if k == 0: a else: b
        print(p.len())
