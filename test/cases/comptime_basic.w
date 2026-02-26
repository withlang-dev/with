// Test basic comptime expressions
comptime fn add(a: i32, b: i32) -> i32: a + b

fn main -> i32:
    let x = comptime add(3, 4)
    println(x)
