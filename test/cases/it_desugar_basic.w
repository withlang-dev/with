//! expect-stdout: 42

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let r = apply(it * 2, 21)
    println(int_to_string(r))
