//! expect-stdout: 52

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let offset = 10
    let result = apply(it + offset, 42)
    print(int_to_string(result))
