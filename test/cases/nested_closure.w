// Test nested closures (non-capturing)
fn apply(f: fn(i32) -> i32, x: i32) -> i32 = f(x)

fn main() -> i32 =
    // Closure returning a closure result
    let double = |x: i32| -> i32 = x * 2
    let add_one = |x: i32| -> i32 = x + 1

    // Nested application
    let result = apply(double, apply(add_one, 5))
    println(result)

    // Direct nested call
    let r2 = double(add_one(3))
    println(r2)
    0
