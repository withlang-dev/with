//! expect-check-fail: non-Copy argument passed to a function that consumes or escapes it

type Pair {
    first: i32,
    second: i32,
}

fn identity(p: Pair) -> Pair:
    p

fn main:
    let p = Pair { first: 1, second: 2 }
    let _ = identity(p)
