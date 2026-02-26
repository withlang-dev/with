// Test passing closures as function arguments
fn apply_twice(f: fn(i32) -> i32, x: i32) -> i32:
    f(f(x))

fn main -> i32:
    let double = |x| x * 2
    let result = apply_twice(double, 3)
    println(result)

    let inc = |x| x + 1
    let r2 = apply_twice(inc, 10)
    println(r2)
