fn greet() -> i32 =
    defer println("goodbye")
    println("hello")
    42

fn main() -> i32 =
    let v = greet()
    println(v)
    0
