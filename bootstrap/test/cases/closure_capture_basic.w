// Test basic closure captures in same scope
fn main -> i32:
    let offset = 10
    let f = |x| x + offset
    println(f(3))
    println(f(32))

    let multiplier = 5
    let g = |x| x * multiplier
    println(g(6))
    println(g(10))
