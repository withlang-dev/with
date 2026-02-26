// Test: higher-order functions with closures

fn apply_twice(f: fn(i32) -> i32, x: i32) -> i32 =
    f(f(x))

fn main() -> i32 =
    // Non-capturing closures work as function pointers
    let doubled = apply_twice(|x| x * 2, 3)
    println(doubled)

    let incremented = apply_twice(|x| x + 1, 10)
    println(incremented)

    let squared = apply_twice(|x| x * x, 2)
    println(squared)

    0
