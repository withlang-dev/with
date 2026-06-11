//! expect-check-fail: use of moved value

type Pair {
    first: i32,
    second: i32,
}

fn identity(p: Pair) -> Pair:
    p

fn main:
    let p = Pair { first: 1, second: 2 }
    let _ = identity(p)
    let _ = p.first
