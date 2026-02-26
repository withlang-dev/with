// Test array comprehension with range
fn main() -> i32 =
    let squares = [x * x for x in 0..5]
    println(squares[0])
    println(squares[1])
    println(squares[2])
    println(squares[3])
    println(squares[4])
    0
