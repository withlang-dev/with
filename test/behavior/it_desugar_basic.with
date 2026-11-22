//! expect-stdout: 42

use std.builtins.int_to_string
fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    let r = apply(it * 2, 21)
    print(int_to_string(r))
