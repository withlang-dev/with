//! expect-error: tuple pattern arity mismatch: 3 patterns besides '..', and the tuple has 2 elements

// #1366 (§9.7): the patterns around a `..` must fit in the tuple.
fn main:
    let (a, b, .., c) = (1, 2)
    print(f"{a} {b} {c}")
