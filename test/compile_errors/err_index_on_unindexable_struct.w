//! expect-check-fail: cannot be indexed

// #1253: subscripting a type that is neither a positional collection nor an
// IndexPlace implementor was accepted by Sema (returned 0 with no error),
// reached MIR as a garbage projection, and rendered as "" inside an f-string.

type Point { x: i32, y: i32 }

fn main:
    let p = Point { x: 1, y: 2 }
    print(f"{p[1]}")
