//! expect-check-fail: type mismatch in binding: parameter 1 is taken as `Bag` (takes) by the function and as `mut Bag` (writes the caller's place) by the type wanted; the two modes do not convert (§3.8a)

// D223: a binding whose function types differ only in a mode names both.
type Bag { n: i32 }
fn plain(b: Bag) -> i32: b.n
fn main:
    let wrong: fn(mut Bag) -> i32 = plain
    print(1)
