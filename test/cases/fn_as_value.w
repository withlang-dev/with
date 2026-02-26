// Test functions as first-class values
fn add(a: i32, b: i32) -> i32: a + b
fn mul(a: i32, b: i32) -> i32: a * b

fn apply_op(f: fn(i32, i32) -> i32, x: i32, y: i32) -> i32:
    f(x, y)

fn main -> i32:
    println(apply_op(add, 3, 4))
    println(apply_op(mul, 3, 4))
