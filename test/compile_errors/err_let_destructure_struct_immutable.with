//! expect-error: cannot assign to immutable variable

// #1354: a `let` struct-pattern destructure binds immutable names.

type P { x: i32, y: i32 }

fn main:
    let P { x, y } = P { x: 1, y: 2 }
    y *= 2
    print(f"{x} {y}")
