fn with_cleanup(n: i32) -> i32:
    defer println("cleanup")
    if n < 0:
        println("negative")
        return -1
    println("positive")
    n * 2

fn main -> i32:
    println(with_cleanup(5))
    println(with_cleanup(-3))
