// POSITIVE: defer executes in LIFO (reverse) order (§2.4)
fn main -> i32:
    println("start")
    defer println("defer 1")
    defer println("defer 2")
    defer println("defer 3")
    println("end")
