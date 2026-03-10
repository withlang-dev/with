//! expect-stdout: 52
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let offset = 10
    let result = apply(move |x| x + offset, 42)
    print(int_to_string(result))
