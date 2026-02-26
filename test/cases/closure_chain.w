// Test closure chaining and higher-order functions
fn apply(f: fn(i32) -> i32, x: i32) -> i32 = f(x)
fn compose(f: fn(i32) -> i32, g: fn(i32) -> i32, x: i32) -> i32 = f(g(x))

fn double(x: i32) -> i32 = x * 2
fn inc(x: i32) -> i32 = x + 1

fn main() -> i32 =
    println(apply(double, 5))
    println(apply(inc, 5))
    println(compose(double, inc, 5))
    println(compose(inc, double, 5))
    0
