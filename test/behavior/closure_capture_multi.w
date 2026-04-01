//! expect-stdout: 60

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let a = 10
    let b = 20
    let result = apply(x => x + a + b, 30)
    print(int_to_string(result))
