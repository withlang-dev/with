// Test nested defer with multiple scopes
fn inner() -> i32 =
    defer println("inner defer 1")
    defer println("inner defer 2")
    42

fn main() -> i32 =
    defer println("main defer")
    let v = inner()
    println(v)
    0
