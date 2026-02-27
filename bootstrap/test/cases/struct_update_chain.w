// Test chained record updates
type Config = { a: i32, b: i32, c: i32 }

fn main -> i32:
    let c1 = Config { a: 1, b: 2, c: 3 }
    let c2 = { c1 with a: 10 }
    let c3 = { c2 with b: 20 }
    println(c3.a)
    println(c3.b)
    println(c3.c)
