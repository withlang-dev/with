//! expect-check-fail: is moved inside a loop

// #1380 (§2.2): an `if` arm that yields an outer binding moves it on every
// iteration, the same as the unconditional `let p = a` in a loop.
fn main:
    let a = "x" ++ "y"
    let b = "u" ++ "v"
    for k in 0..2:
        let p = if k == 0: a else: b
        print(p)
