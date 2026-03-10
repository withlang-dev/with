//! expect-stdout: 42
fn double(x: i32) -> i32:
    x * 2

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let result = apply(double, 21)
    println(int_to_string(result))
