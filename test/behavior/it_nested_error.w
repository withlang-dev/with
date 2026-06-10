//! expect-error: nested implicit closure is ambiguous; use explicit parameter for inner closure [E0951]

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn transform(f: fn(i32) -> i32, g: fn(i32) -> i32, x: i32) -> i32:
    f(g(x))

fn main:
    let r = apply(it + transform(it * 3, x => x, 1), 10)
    print(int_to_string(r))
