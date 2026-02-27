// POSITIVE: comptime fn evaluation (§17.1)
comptime fn double(x: i32) -> i32:
    x * 2

comptime fn add(a: i32, b: i32) -> i32:
    a + b

fn main -> i32:
    let a = comptime double(21)
    assert(a == 42)

    let b = comptime add(10, 32)
    assert(b == 42)

    // comptime if
    let c = comptime if true then 42 else 99
    assert(c == 42)

    println("comptime fn ok")
