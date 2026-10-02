//! expect-stdout: 9
//! expect-stdout: 11
//! expect-stdout: 30

// #1766: a closure is a fn value: a function taking `fn(i32) -> i32` is
// called with a capturing closure and with a named function, and calls
// through the pair the same way for both.
fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)
fn triple(x: i32) -> i32: x * 3

fn main:
    let base = 6
    print(apply(x => x + 3, base))
    print(apply(x => x + base - 1, base))
    print(apply(triple, 10))
