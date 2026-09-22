//! expect-error: cannot assign to immutable variable

// #1354: a nested `let` destructure binds immutable names at every depth.

fn main:
    let ((a, b), c) = ((1, 2), 3)
    b += 1
    print(f"{a} {b} {c}")
