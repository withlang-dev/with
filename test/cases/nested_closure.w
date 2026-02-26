// Test nested closures (non-capturing)
fn apply(f: fn(i32) -> i32, x: i32) -> i32 = f(x)

fn double(x: i32) -> i32 = x * 2
fn add_one(x: i32) -> i32 = x + 1

fn main() -> i32 =
    // Nested application
    let result = apply(double, apply(add_one, 5))
    println(result)

    // Direct nested call
    let r2 = double(add_one(3))
    println(r2)
    0
