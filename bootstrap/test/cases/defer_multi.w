// Test multiple defers in LIFO order
fn main -> i32:
    println("start")
    defer println("defer 1")
    defer println("defer 2")
    defer println("defer 3")
    println("middle")
