//! expect-check-fail: is moved inside a loop

// #1380 (§2.2): an `if` arm that yields an outer binding moves it on every
// iteration, the same as the unconditional `let p = a` in a loop. A List,
// not a str: a str is a value and is copied (D111).
fn main:
    let a: List[i32] = [1]
    let b: List[i32] = [2]
    for k in 0..2:
        let p = if k == 0: a else: b
        print(p.len())
