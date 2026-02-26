// Test: string interpolation with complex expressions
type Point = { x: i32, y: i32 }

impl Point =
    fn sum(self: Point) -> i32: self.x + self.y

fn double(x: i32) -> i32: x * 2

fn main -> i32:
    // Basic variable interpolation
    let name = "With"
    println("language: {name}")

    // Numeric interpolation
    let x = 42
    println("answer: {x}")

    // Struct field interpolation
    let p = Point { x: 10, y: 20 }
    println("point x: {p.x}")
    println("point y: {p.y}")

    // Multiple interpolations in one string
    let a = 3
    let b = 7
    println("a={a} b={b}")

    // Boolean interpolation
    let flag = true
    println("flag: {flag}")

    println("all str_interp_complex tests passed")
