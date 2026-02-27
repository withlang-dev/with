fn double(x: i32) -> i32: x * 2
fn add_one(x: i32) -> i32: x + 1

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main -> i32:
    println(apply(double, 5))
    println(apply(add_one, 5))
    println(double(add_one(3)))
    println(add_one(double(3)))
