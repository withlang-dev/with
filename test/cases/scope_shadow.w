// Test variable shadowing in nested scopes
fn main -> i32:
    let x = 10
    println(x)
    let x = 20
    println(x)
    let x = x + 5
    println(x)
