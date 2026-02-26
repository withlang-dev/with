// Test advanced string interpolation
fn main() -> i32 =
    let name = "Alice"
    let age = 30
    let score = 95
    println("Name: {name}")
    println("Age: {age}")
    println("Score: {score}")
    // Nested field access in interpolation
    let x = 42
    let y = 58
    println("x={x}, y={y}")
    0
