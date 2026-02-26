fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)

fn main -> i32:
    // forward: double >> add1 = |x| add1(double(x))
    let f = double >> add1
    println(f(5))

    let r1 = apply(f, 5)
    println(r1)

    // backward: add1 << double = |x| add1(double(x))
    let g = add1 << double
    println(g(5))

    let r2 = apply(g, 3)
    println(r2)

